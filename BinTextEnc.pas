unit BinTextEnc;

interface

type
{$IFDEF x64}
  PtrUInt = UInt64;
{$ELSE}
  PtrUInt = LongWord;
{$ENDIF}

{$IF not Defined(FPC) or not Defined(Unicode)}
  UnicodeChar   = WideChar;
  PUnicodeChar  = ^UnicodeChar;
  UnicodeString = WideString;
{$IFEND}

  TBinTextEncoding = (bteBase2,bteBase8,bteBase10,bteNumber,bteBase16,
                      bteHexadecimal,bteBase32,bteBase32Hex,bteBase64,
                      bteBase85);

const
  AnsiEncodingTable_Base2: Array[0..1] of AnsiChar =
    ('0','1');
  WideEncodingTable_Base2: Array[0..1] of UnicodeChar =
    ('0','1');

Function EncodedLength_Base2(DataSize: Integer; Header: Boolean = False): Integer;

Function DecodedLength_Base2(Str: UnicodeString; Header: Boolean = False): Integer;

{------------------------------------------------------------------------------}

Function EncodeBase2(Data: Pointer; Size: Integer; Reversed: Boolean = False): String; overload;
Function AnsiEncodeBase2(Data: Pointer; Size: Integer; Reversed: Boolean = False): AnsiString; overload;
Function WideEncodeBase2(Data: Pointer; Size: Integer; Reversed: Boolean = False): UnicodeString; overload;

Function EncodeBase2(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of Char): String; overload;
Function AnsiEncodeBase2(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of AnsiChar): AnsiString; overload;
Function WideEncodeBase2(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of UnicodeChar): UnicodeString; overload;

{------------------------------------------------------------------------------}

Function DecodeBase2(const Str: String; out Size: Integer; Reversed: Boolean = False): Pointer; overload;
Function AnsiDecodeBase2(const Str: AnsiString; out Size: Integer; Reversed: Boolean = False): Pointer; overload;
Function WideDecodeBase2(const Str: UnicodeString; out Size: Integer; Reversed: Boolean = False): Pointer; overload;

Function DecodeBase2(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer; overload;
Function AnsiDecodeBase2(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer; overload;
Function WideDecodeBase2(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer; overload;

Function DecodeBase2(const Str: String; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of Char): Pointer; overload;
Function AnsiDecodeBase2(const Str: AnsiString; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Pointer; overload;
Function WideDecodeBase2(const Str: UnicodeString; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of WideChar): Pointer; overload;

Function DecodeBase2(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of Char): Integer; overload;
Function AnsiDecodeBase2(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Integer; overload;
Function WideDecodeBase2(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of WideChar): Integer; overload;


implementation

uses
  SysUtils;

{$MESSAGE 'temporary'}
const
  headerlength = 4;

{==============================================================================}
{------------------------------------------------------------------------------}
{    Auxiliary functions                                                       }
{------------------------------------------------------------------------------}
{==============================================================================}

procedure ResolveDataPointer(var Ptr: Pointer; Reversed: Boolean; Size: LongWord; EndOffset: LongWord = 1);
begin
If Reversed then
  Ptr := Pointer(PtrUInt(Ptr) + Size - EndOffset)
end;

{------------------------------------------------------------------------------}

procedure AdvanceDataPointer(var Ptr: Pointer; Reversed: Boolean);
begin
If Reversed then Dec(PByte(Ptr))
  else Inc(PByte(Ptr));
end;

{------------------------------------------------------------------------------}

procedure DecodeCheckSize(Size, Required, Base: Integer);
begin
If Size < Required then
  raise Exception.CreateFmt('Decoding @ Base%d: Buffer too small (%d, required %d).',[Base,Size,Required]);
end;

{------------------------------------------------------------------------------}

Function WideTableIndex(const aChar: WideChar; const Table: Array of WideChar; Base: Integer): Byte;
begin
For Result := Low(Table) to High(Table) do
  If Table[Result] = aChar then Exit;
raise Exception.CreateFmt('WideTableIndex @ Base%d: Invalid character "%s" (#%d).',[Base,aChar,Ord(aChar)]);
end;

{------------------------------------------------------------------------------}

Function AnsiTableIndex(const aChar: AnsiChar; const Table: Array of AnsiChar; Base: Integer): Byte;
begin
For Result := Low(Table) to High(Table) do
  If Table[Result] = aChar then Exit;
raise Exception.CreateFmt('WideTableIndex @ Base%d: Invalid character "%s" (#%d).',[Base,aChar,Ord(aChar)]);
end;

{==============================================================================}
{------------------------------------------------------------------------------}
{    Functions calculating length of encoded text from size of data that has   }
{    to be encoded                                                             }
{------------------------------------------------------------------------------}
{==============================================================================}

Function EncodedLength_Base2(DataSize: Integer; Header: Boolean = False): Integer;
begin
Result := DataSize * 8;
If Header then Result := Result + HeaderLength;
end;

{==============================================================================}
{------------------------------------------------------------------------------}
{    Functions calculating size of encoded data from length of encoded text    }
{------------------------------------------------------------------------------}
{==============================================================================}

Function DecodedLength_Base2(Str: UnicodeString; Header: Boolean = False): Integer;
begin
If Header then Result := (Length(Str) - HeaderLength) div 8
  else Result := Length(Str) div 8;
If Result < 0 then Result := 0;
end;

{==============================================================================}
{------------------------------------------------------------------------------}
{    Encoding functions                                                        }
{------------------------------------------------------------------------------}
{==============================================================================}

Function EncodeBase2(Data: Pointer; Size: Integer; Reversed: Boolean = False): String;
begin
{$IFDEF Unicode}
Result := WideEncodeBase2(Data,Size,Reversed);
{$ELSE}
Result := AnsiEncodeBase2(Data,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncodeBase2(Data: Pointer; Size: Integer; Reversed: Boolean = False): AnsiString;
begin
Result := AnsiEncodeBase2(Data,Size,Reversed,AnsiEncodingTable_Base2);
end;

{------------------------------------------------------------------------------}

Function WideEncodeBase2(Data: Pointer; Size: Integer; Reversed: Boolean = False): UnicodeString;
begin
Result := WideEncodeBase2(Data,Size,Reversed,WideEncodingTable_Base2);
end;

{------------------------------------------------------------------------------}

Function EncodeBase2(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of Char): String;
begin
{$IFDEF Unicode}
Result := WideEncodeBase2(Data,Size,Reversed,EncodingTable);
{$ELSE}
Result := AnsiEncodeBase2(Data,Size,Reversed,EncodingTable);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncodeBase2(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of AnsiChar): AnsiString;
var
  Buffer: Byte;
  i,j:    Integer;
begin
ResolveDataPointer(Data,Reversed,Size);
SetLength(Result,EncodedLength_Base2(Size));
For i := 0 to Pred(Size) do
  begin
    Buffer := PByte(Data)^;
    For j := 8 downto 1 do
      begin
        Result[(i * 8) + j] := EncodingTable[Buffer and 1];
        Buffer := Buffer shr 1;
      end;
    AdvanceDataPointer(Data,Reversed)
  end;
end;

{------------------------------------------------------------------------------}

Function WideEncodeBase2(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of UnicodeChar): UnicodeString;
var
  Buffer: Byte;
  i,j:    Integer;
begin
ResolveDataPointer(Data,Reversed,Size);
SetLength(Result,EncodedLength_Base2(Size));
For i := 0 to Pred(Size) do
  begin
    Buffer := PByte(Data)^;
    For j := 8 downto 1 do
      begin
        Result[(i * 8) + j] := EncodingTable[Buffer and 1];
        Buffer := Buffer shr 1;
      end;
    AdvanceDataPointer(Data,Reversed);
  end;
end;

{==============================================================================}
{------------------------------------------------------------------------------}
{    Decoding functions                                                        }
{------------------------------------------------------------------------------}
{==============================================================================}

Function DecodeBase2(const Str: String; out Size: Integer; Reversed: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecodeBase2(Str,Size,Reversed);
{$ELSE}
Result := AnsiDecodeBase2(Str,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodeBase2(const Str: AnsiString; out Size: Integer; Reversed: Boolean = False): Pointer;
begin
Result := AnsiDecodeBase2(Str,Size,Reversed,AnsiEncodingTable_Base2);
end;

{------------------------------------------------------------------------------}

Function WideDecodeBase2(const Str: UnicodeString; out Size: Integer; Reversed: Boolean = False): Pointer;
begin
Result := WideDecodeBase2(Str,Size,Reversed,WideEncodingTable_Base2);
end;

{------------------------------------------------------------------------------}

Function DecodeBase2(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer;
begin
{$IFDEF Unicode}
Result := WideDecodeBase2(Str,Ptr,Size,Reversed);
{$ELSE}
Result := AnsiDecodeBase2(Str,Ptr,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodeBase2(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer;
begin
Result := AnsiDecodeBase2(Str,Ptr,Size,Reversed,AnsiEncodingTable_Base2);
end;

{------------------------------------------------------------------------------}

Function WideDecodeBase2(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer;
begin
Result := WideDecodeBase2(Str,Ptr,Size,Reversed,WideEncodingTable_Base2);
end;

{------------------------------------------------------------------------------}

Function DecodeBase2(const Str: String; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of Char): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecodeBase2(Str,Size,Reversed,DecodingTable);
{$ELSE}
Result := AnsiDecodeBase2(Str,Size,Reversed,DecodingTable);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodeBase2(const Str: AnsiString; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Pointer;
begin
Size := DecodedLength_Base2(Str);
Result := AllocMem(Size);
try
  Size := AnsiDecodeBase2(Str,Result,Size,Reversed,DecodingTable);
except
  FreeMem(Result,Size);
  Result := nil;
  Size := 0;
  raise;
end;
end;

{------------------------------------------------------------------------------}

Function WideDecodeBase2(const Str: UnicodeString; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of WideChar): Pointer;
begin
Size := DecodedLength_Base2(Str);
Result := AllocMem(Size);
try
  Size := WideDecodeBase2(Str,Result,Size,Reversed,DecodingTable);
except
  FreeMem(Result,Size);
  Result := nil;
  Size := 0;
  raise;
end;
end;

{------------------------------------------------------------------------------}

Function DecodeBase2(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of Char): Integer;
begin
{$IFDEF Unicode}
Result := WideDecodeBase2(Str,Ptr,Size,Reversed,DecodingTable);
{$ELSE}
Result := AnsiDecodeBase2(Str,Ptr,Size,Reversed,DecodingTable);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodeBase2(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Integer;
var
  Buffer: Byte;
  i,j:    Integer;
begin
Result := DecodedLength_Base2(Str);
DecodeCheckSize(Size,Result,2);
ResolveDataPointer(Ptr,Reversed,Size);
For i := 0 to Pred(Result) do
  begin
    Buffer := 0;
    For j := 1 to 8 do
      Buffer := (Buffer shl 1) or AnsiTableIndex(Str[(i * 8) + j],DecodingTable,2);
    PByte(Ptr)^ := Buffer;
    AdvanceDataPointer(Ptr,Reversed);
  end;
end;

{------------------------------------------------------------------------------}

Function WideDecodeBase2(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of WideChar): Integer;
var
  Buffer: Byte;
  i,j:    Integer;
begin
Result := DecodedLength_Base2(Str);
DecodeCheckSize(Size,Result,2);
ResolveDataPointer(Ptr,Reversed,Size);
For i := 0 to Pred(Result) do
  begin
    Buffer := 0;
    For j := 1 to 8 do
      Buffer := (Buffer shl 1) or WideTableIndex(Str[(i * 8) + j],DecodingTable,2);
    PByte(Ptr)^ := Buffer;
    AdvanceDataPointer(Ptr,Reversed);
  end;
end;


end.
