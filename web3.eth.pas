{******************************************************************************}
{                                                                              }
{                                  Delphereum                                  }
{                                                                              }
{             Copyright(c) 2018 Stefan van As <svanas@runbox.com>              }
{           Github Repository <https://github.com/svanas/delphereum>           }
{                                                                              }
{   Distributed under Creative Commons NonCommercial (aka CC BY-NC) license.   }
{                                                                              }
{******************************************************************************}

unit web3.eth;

{$I web3.inc}

interface

uses
  // Velthuis' BigNumbers
  Velthuis.BigIntegers,
  // Web3
  web3,
  web3.eth.types,
  web3.types;

const
  BLOCK_EARLIEST = 'earliest';
  BLOCK_LATEST   = 'latest';
  BLOCK_PENDING  = 'pending';

const
  ADDRESS_ZERO: TAddress = '0x0000000000000000000000000000000000000000';

function  blockNumber(client: TWeb3): BigInteger; overload;
procedure blockNumber(client: TWeb3; callback: TASyncQuantity); overload;

procedure getBalance(client: TWeb3; address: TAddress; callback: TASyncQuantity); overload;
procedure getBalance(client: TWeb3; address: TAddress; const block: string; callback: TASyncQuantity); overload;

procedure getTransactionCount(client: TWeb3; address: TAddress; callback: TASyncQuantity); overload;
procedure getTransactionCount(client: TWeb3; address: TAddress; const block: string; callback: TASyncQuantity); overload;

procedure call(client: TWeb3; &to: TAddress; const func: string; args: array of const; callback: TASyncString); overload;
procedure call(client: TWeb3; from, &to: TAddress; const func: string; args: array of const; callback: TASyncString); overload;
procedure call(client: TWeb3; &to: TAddress; const func, block: string; args: array of const; callback: TASyncString); overload;
procedure call(client: TWeb3; from, &to: TAddress; const func, block: string; args: array of const; callback: TASyncString); overload;

procedure call(client: TWeb3; &to: TAddress; const func: string; args: array of const; callback: TASyncQuantity); overload;
procedure call(client: TWeb3; from, &to: TAddress; const func: string; args: array of const; callback: TASyncQuantity); overload;
procedure call(client: TWeb3; &to: TAddress; const func, block: string; args: array of const; callback: TASyncQuantity); overload;
procedure call(client: TWeb3; from, &to: TAddress; const func, block: string; args: array of const; callback: TASyncQuantity); overload;

procedure call(client: TWeb3; &to: TAddress; const func: string; args: array of const; callback: TASyncBoolean); overload;
procedure call(client: TWeb3; from, &to: TAddress; const func: string; args: array of const; callback: TASyncBoolean); overload;
procedure call(client: TWeb3; &to: TAddress; const func, block: string; args: array of const; callback: TASyncBoolean); overload;
procedure call(client: TWeb3; from, &to: TAddress; const func, block: string; args: array of const; callback: TASyncBoolean); overload;

procedure call(client: TWeb3; &to: TAddress; const func: string; args: array of const; callback: TASyncTuple); overload;
procedure call(client: TWeb3; from, &to: TAddress; const func: string; args: array of const; callback: TASyncTuple); overload;
procedure call(client: TWeb3; &to: TAddress; const func, block: string; args: array of const; callback: TASyncTuple); overload;
procedure call(client: TWeb3; from, &to: TAddress; const func, block: string; args: array of const; callback: TASyncTuple); overload;

function sign(privateKey: TPrivateKey; const msg: string): TSignature;

procedure write(
  client    : TWeb3;
  from      : TPrivateKey;
  &to       : TAddress;
  const func: string;
  args      : array of const;
  callback  : TASyncReceipt); overload;

procedure write(
  client    : TWeb3;
  from      : TPrivateKey;
  &to       : TAddress;
  const func: string;
  args      : array of const;
  gasPrice  : TWei;
  gasLimit  : TWei;
  callback  : TASyncReceipt); overload;

procedure write(
  client    : TWeb3;
  from      : TPrivateKey;
  &to       : TAddress;
  const data: string;
  gasPrice  : TWei;
  gasLimit  : TWei;
  callback  : TASyncReceipt); overload;

implementation

uses
  // Delphi
  System.JSON,
  System.SysUtils,
  // CryptoLib4Pascal
  ClpBigInteger,
  ClpIECPrivateKeyParameters,
  // Web3
  web3.crypto,
  web3.eth.abi,
  web3.eth.crypto,
  web3.eth.gas,
  web3.eth.tx,
  web3.json,
  web3.json.rpc,
  web3.utils;

function blockNumber(client: TWeb3): BigInteger;
var
  obj: TJsonObject;
begin
  obj := web3.json.rpc.send(client.URL, 'eth_blockNumber', []);
  if Assigned(obj) then
  try
    Result := web3.json.getPropAsStr(obj, 'result');
  finally
    obj.Free;
  end;
end;

procedure blockNumber(client: TWeb3; callback: TASyncQuantity);
begin
  web3.json.rpc.send(client.URL, 'eth_blockNumber', [], procedure(resp: TJsonObject; err: Exception)
  begin
    if Assigned(err) then
      callback(0, err)
    else
      callback(web3.json.getPropAsStr(resp, 'result'), nil);
  end);
end;

procedure getBalance(client: TWeb3; address: TAddress; callback: TASyncQuantity);
begin
  getBalance(client, address, BLOCK_LATEST, callback);
end;

procedure getBalance(client: TWeb3; address: TAddress; const block: string; callback: TASyncQuantity);
begin
  web3.json.rpc.send(client.URL, 'eth_getBalance', [address, block], procedure(resp: TJsonObject; err: Exception)
  begin
    if Assigned(err) then
      callback(0, err)
    else
      callback(web3.json.getPropAsStr(resp, 'result'), nil);
  end);
end;

procedure getTransactionCount(client: TWeb3; address: TAddress; callback: TASyncQuantity);
begin
  getTransactionCount(client, address, BLOCK_LATEST, callback);
end;

// returns the number of transations *sent* from an address
procedure getTransactionCount(client: TWeb3; address: TAddress; const block: string; callback: TASyncQuantity);
begin
  web3.json.rpc.send(client.URL, 'eth_getTransactionCount', [address, block], procedure(resp: TJsonObject; err: Exception)
  begin
    if Assigned(err) then
      callback(0, err)
    else
      callback(web3.json.getPropAsStr(resp, 'result'), nil);
  end);
end;

procedure call(client: TWeb3; &to: TAddress; const func: string; args: array of const; callback: TASyncString);
begin
  call(client, ADDRESS_ZERO, &to, func, args, callback);
end;

procedure call(client: TWeb3; from, &to: TAddress; const func: string; args: array of const; callback: TASyncString);
begin
  call(client, from, &to, func, BLOCK_LATEST, args, callback);
end;

procedure call(client: TWeb3; &to: TAddress; const func, block: string; args: array of const; callback: TASyncString);
begin
  call(client, ADDRESS_ZERO, &to, func, block, args, callback);
end;

procedure call(client: TWeb3; from, &to: TAddress; const func, block: string; args: array of const; callback: TASyncString);
var
  abi: string;
  obj: TJsonObject;
begin
  // step #1: encode the function abi
  abi := web3.eth.abi.encode(func, args);
  // step #2: construct the transaction call object
  obj := web3.json.unmarshal(Format(
    '{"from": %s, "to": %s, "data": %s}', [
      web3.json.quoteString(string(from), '"'),
      web3.json.quoteString(string(&to), '"'),
      web3.json.quoteString(abi, '"')
    ]
  ));
  try
    // step #3: execute a message call (without creating a transaction on the blockchain)
    web3.json.rpc.send(client.URL, 'eth_call', [obj, block], procedure(resp: TJsonObject; err: Exception)
    begin
      if Assigned(err) then
        callback('', err)
      else
        callback(web3.json.getPropAsStr(resp, 'result'), nil);
    end);
  finally
    obj.Free;
  end;
end;

procedure call(client: TWeb3; &to: TAddress; const func: string; args: array of const; callback: TASyncQuantity);
begin
  call(client, ADDRESS_ZERO, &to, func, args, callback);
end;

procedure call(client: TWeb3; from, &to: TAddress; const func: string; args: array of const; callback: TASyncQuantity);
begin
  call(client, from, &to, func, BLOCK_LATEST, args, callback);
end;

procedure call(client: TWeb3; &to: TAddress; const func, block: string; args: array of const; callback: TASyncQuantity);
begin
  call(client, ADDRESS_ZERO, &to, func, block, args, callback);
end;

procedure call(client: TWeb3; from, &to: TAddress; const func, block: string; args: array of const; callback: TASyncQuantity);
begin
  call(client, from, &to, func, block, args, procedure(const hex: string; err: Exception)
  begin
    if Assigned(err) then
      callback(0, err)
    else
      if (hex = '') or (hex = '0x') then
        callback(0, nil)
      else
        callback(hex, nil);
  end);
end;

procedure call(client: TWeb3; &to: TAddress; const func: string; args: array of const; callback: TASyncBoolean);
begin
  call(client, ADDRESS_ZERO, &to, func, args, callback);
end;

procedure call(client: TWeb3; from, &to: TAddress; const func: string; args: array of const; callback: TASyncBoolean);
begin
  call(client, from, &to, func, BLOCK_LATEST, args, callback);
end;

procedure call(client: TWeb3; &to: TAddress; const func, block: string; args: array of const; callback: TASyncBoolean);
begin
  call(client, ADDRESS_ZERO, &to, func, block, args, callback);
end;

procedure call(client: TWeb3; from, &to: TAddress; const func, block: string; args: array of const; callback: TASyncBoolean);
begin
  call(client, from, &to, func, block, args, procedure(const hex: string; err: Exception)
  var
    buf: TBytes;
  begin
    if Assigned(err) then
      callback(False, err)
    else
    begin
      buf := fromHex(hex);
      callback((Length(buf) > 0) and (buf[High(buf)] <> 0), nil);
    end;
  end);
end;

procedure call(client: TWeb3; &to: TAddress; const func: string; args: array of const; callback: TASyncTuple);
begin
  call(client, ADDRESS_ZERO, &to, func, args, callback);
end;

procedure call(client: TWeb3; from, &to: TAddress; const func: string; args: array of const; callback: TASyncTuple);
begin
  call(client, from, &to, func, BLOCK_LATEST, args, callback);
end;

procedure call(client: TWeb3; &to: TAddress; const func, block: string; args: array of const; callback: TASyncTuple);
begin
  call(client, ADDRESS_ZERO, &to, func, block, args, callback);
end;

procedure call(client: TWeb3; from, &to: TAddress; const func, block: string; args: array of const; callback: TASyncTuple);
var
  buf: TBytes;
  tup: TTuple;
begin
  call(client, from, &to, func, block, args, procedure(const hex: string; err: Exception)
  begin
    if Assigned(err) then
      callback([], err)
    else
    begin
      buf := web3.utils.fromHex(hex);
      while Length(buf) >= 32 do
      begin
        SetLength(tup, Length(tup) + 1);
        Move(buf[0], tup[High(tup)][0], 32);
        Delete(buf, 0, 32);
      end;
      callback(tup, nil);
    end;
  end);
end;

function sign(privateKey: TPrivateKey; const msg: string): TSignature;
var
  Params   : IECPrivateKeyParameters;
  Signer   : TEthereumSigner;
  Signature: TECDsaSignature;
  v        : TBigInteger;
begin
  Params := web3.eth.crypto.PrivateKeyFromHex(privateKey);
  Signer := TEthereumSigner.Create;
  try
    Signer.Init(True, Params);
    Signature := Signer.GenerateSignature(
      sha3(
        TEncoding.UTF8.GetBytes(
          #25 + 'Ethereum Signed Message:' + #10 + IntToStr(Length(msg)) + msg
        )
      )
    );
    v := Signature.rec.Add(TBigInteger.ValueOf(27));
    Result := TSignature(
      toHex(
        Signature.r.ToByteArrayUnsigned +
        Signature.s.ToByteArrayUnsigned +
        v.ToByteArrayUnsigned
      )
    );
  finally
    Signer.Free;
  end;
end;

procedure write(
  client    : TWeb3;
  from      : TPrivateKey;
  &to       : TAddress;
  const func: string;
  args      : array of const;
  callback  : TASyncReceipt);
var
  data: string;
begin
  data := web3.eth.abi.encode(func, args);
  web3.eth.gas.getGasPrice(client, procedure(gasPrice: BigInteger; err: Exception)
  begin
    if Assigned(err) then
      callback(nil, err)
    else
      write(client, from, &to, data, gasPrice, 200000, callback);
  end);
end;

procedure write(
  client    : TWeb3;
  from      : TPrivateKey;
  &to       : TAddress;
  const func: string;
  args      : array of const;
  gasPrice  : TWei;
  gasLimit  : TWei;
  callback  : TASyncReceipt);
begin
  write(client, from, &to, web3.eth.abi.encode(func, args), gasPrice, gasLimit, callback);
end;

procedure write(
  client    : TWeb3;
  from      : TPrivateKey;
  &to       : TAddress;
  const data: string;
  gasPrice  : TWei;
  gasLimit  : TWei;
  callback  : TASyncReceipt);
begin
  web3.eth.getTransactionCount(
    client,
    web3.eth.crypto.AddressFromPrivateKey(web3.eth.crypto.PrivateKeyFromHex(from)),
    procedure(qty: BigInteger; err: Exception)
    begin
      if Assigned(err) then
        callback(nil, err)
      else
        sendTransactionEx(
          client,
          signTransaction(
            client.Chain,
            qty,
            from, &to,
            0,
            data,
            gasPrice, gasLimit),
          callback);
    end
  );
end;

end.
