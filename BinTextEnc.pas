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

  TBinTextEncoding = (bteUnknown,bteBase2,bteBase8,bteBase10,bteNumber,
                      bteBase16,bteHexadecimal,bteBase32,bteBase32Hex,
                      bteBase64,bteBase85);

const
  AnsiPaddingChar_Base8     = AnsiChar('=');
  AnsiPaddingChar_Base32    = AnsiChar('=');
  AnsiPaddingChar_Base32Hex = AnsiChar('=');
  AnsiPaddingChar_Base64    = AnsiChar('=');

  WidePaddingChar_Base8     = UnicodeChar('=');
  WidePaddingChar_Base32    = UnicodeChar('=');
  WidePaddingChar_Base32Hex = UnicodeChar('=');
  WidePaddingChar_Base64    = UnicodeChar('=');

  AnsiCompressionChar_Base85: AnsiChar    = '_';
  WideCompressionChar_Base85: UnicodeChar = '_';

  AnsiEncodingTable_Base2: Array[0..1] of AnsiChar =
    ('0','1');
  WideEncodingTable_Base2: Array[0..1] of UnicodeChar =
    ('0','1');

  AnsiEncodingTable_Base8: Array[0..7] of AnsiChar =
    ('0','1','2','3','4','5','6','7');
  WideEncodingTable_Base8: Array[0..7] of UnicodeChar =
    ('0','1','2','3','4','5','6','7');

  AnsiEncodingTable_Base10: Array[0..9] of AnsiChar =
    ('0','1','2','3','4','5','6','7','8','9');
  WideEncodingTable_Base10: Array[0..9] of UnicodeChar =
    ('0','1','2','3','4','5','6','7','8','9');

  AnsiEncodingTable_Number: Array[0..9] of AnsiChar =
    ('0','1','2','3','4','5','6','7','8','9');
  WideEncodingTable_Number: Array[0..9] of UnicodeChar =
    ('0','1','2','3','4','5','6','7','8','9');

  AnsiEncodingTable_Base16: Array[0..15] of AnsiChar =
    ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
  WideEncodingTable_Base16: Array[0..15] of UnicodeChar =
    ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');

  AnsiEncodingTable_Hexadecimal: Array[0..15] of AnsiChar =
    ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
  WideEncodingTable_Hexadecimal: Array[0..15] of UnicodeChar =
    ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');

  AnsiEncodingTable_Base32: Array[0..31] of AnsiChar =
    ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
     'Q','R','S','T','U','V','W','X','Y','Z','2','3','4','5','6','7');
  WideEncodingTable_Base32: Array[0..31] of UnicodeChar =
    ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
     'Q','R','S','T','U','V','W','X','Y','Z','2','3','4','5','6','7');

  AnsiEncodingTable_Base32Hex: Array[0..31] of AnsiChar =
    ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F',
     'G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V');
  WideEncodingTable_Base32Hex: Array[0..31] of UnicodeChar =
    ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F',
     'G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V');

  AnsiEncodingTable_Base64: Array[0..63] of AnsiChar =
    ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
     'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
     'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
     'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/');
  WideEncodingTable_Base64: Array[0..63] of UnicodeChar =
    ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
     'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
     'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
     'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/');

  AnsiEncodingTable_Base85: Array[0..84] of AnsiChar =
    ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F',
     'G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V',
     'W','X','Y','Z','a','b','c','d','e','f','g','h','i','j','k','l',
     'm','n','o','p','q','r','s','t','u','v','w','x','y','z','.','-',
     ':','+','=','^','!','/','*','?','&','<','>','(',')','[',']','{',
     '}','@','%','$','#');
  WideEncodingTable_Base85: Array[0..84] of UnicodeChar =
    ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F',
     'G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V',
     'W','X','Y','Z','a','b','c','d','e','f','g','h','i','j','k','l',
     'm','n','o','p','q','r','s','t','u','v','w','x','y','z','.','-',
     ':','+','=','^','!','/','*','?','&','<','>','(',')','[',']','{',
     '}','@','%','$','#');

{------------------------------------------------------------------------------}     

Function EncodedLength_Base2(DataSize: Integer; Header: Boolean = False): Integer;
Function EncodedLength_Base8(DataSize: Integer; Header: Boolean = False; Padding: Boolean = True): Integer;
Function EncodedLength_Base10(DataSize: Integer; Header: Boolean = False): Integer;
Function EncodedLength_Number(DataSize: Integer; Header: Boolean = False): Integer;
Function EncodedLength_Base16(DataSize: Integer; Header: Boolean = False): Integer;
Function EncodedLength_Hexadecimal(DataSize: Integer; Header: Boolean = False): Integer;
Function EncodedLength_Base32(DataSize: Integer; Header: Boolean = False; Padding: Boolean = True): Integer;
Function EncodedLength_Base32Hex(DataSize: Integer; Header: Boolean = False; Padding: Boolean = True): Integer;
Function EncodedLength_Base64(DataSize: Integer; Header: Boolean = False; Padding: Boolean = True): Integer;
Function EncodedLength_Base85(DataSize: Integer; Header: Boolean = False; Trim: Boolean = False): Integer;

{------------------------------------------------------------------------------}

Function DecodedLength_Base2(const Str: String; Header: Boolean = False): Integer;
Function AnsiDecodedLength_Base2(const Str: AnsiString; Header: Boolean = False): Integer;
Function WideDecodedLength_Base2(const Str: UnicodeString; Header: Boolean = False): Integer;

Function DecodedLength_Base8(const Str: String; Header: Boolean = False): Integer; overload;
Function AnsiDecodedLength_Base8(const Str: AnsiString; Header: Boolean = False): Integer; overload;
Function WideDecodedLength_Base8(const Str: UnicodeString; Header: Boolean = False): Integer; overload;
Function DecodedLength_Base8(const Str: String; Header: Boolean; PaddingChar: Char): Integer; overload;
Function AnsiDecodedLength_Base8(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): Integer; overload;
Function WideDecodedLength_Base8(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): Integer; overload;

Function DecodedLength_Base10(const Str: String; Header: Boolean = False): Integer;
Function AnsiDecodedLength_Base10(const Str: AnsiString; Header: Boolean = False): Integer;
Function WideDecodedLength_Base10(const Str: UnicodeString; Header: Boolean = False): Integer;

Function DecodedLength_Number(const Str: String; Header: Boolean = False): Integer;
Function AnsiDecodedLength_Number(const Str: AnsiString; Header: Boolean = False): Integer;
Function WideDecodedLength_Number(const Str: UnicodeString; Header: Boolean = False): Integer;

Function DecodedLength_Base16(const Str: String; Header: Boolean = False): Integer;
Function AnsiDecodedLength_Base16(const Str: AnsiString; Header: Boolean = False): Integer;
Function WideDecodedLength_Base16(const Str: UnicodeString; Header: Boolean = False): Integer;

Function DecodedLength_Hexadecimal(const Str: String; Header: Boolean = False): Integer;
Function AnsiDecodedLength_Hexadecimal(const Str: AnsiString; Header: Boolean = False): Integer;
Function WideDecodedLength_Hexadecimal(const Str: UnicodeString; Header: Boolean = False): Integer;

Function DecodedLength_Base32(const Str: String; Header: Boolean = False): Integer; overload;
Function AnsiDecodedLength_Base32(const Str: AnsiString; Header: Boolean = False): Integer; overload;
Function WideDecodedLength_Base32(const Str: UnicodeString; Header: Boolean = False): Integer; overload;
Function DecodedLength_Base32(const Str: String; Header: Boolean; PaddingChar: Char): Integer; overload;
Function AnsiDecodedLength_Base32(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): Integer; overload;
Function WideDecodedLength_Base32(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): Integer; overload;

Function DecodedLength_Base32Hex(const Str: String; Header: Boolean = False): Integer; overload;
Function AnsiDecodedLength_Base32Hex(const Str: AnsiString; Header: Boolean = False): Integer; overload;
Function WideDecodedLength_Base32Hex(const Str: UnicodeString; Header: Boolean = False): Integer; overload;
Function DecodedLength_Base32Hex(const Str: String; Header: Boolean; PaddingChar: Char): Integer; overload;
Function AnsiDecodedLength_Base32Hex(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): Integer; overload;
Function WideDecodedLength_Base32Hex(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): Integer; overload;

Function DecodedLength_Base64(const Str: String; Header: Boolean = False): Integer; overload;
Function AnsiDecodedLength_Base64(const Str: AnsiString; Header: Boolean = False): Integer; overload;
Function WideDecodedLength_Base64(const Str: UnicodeString; Header: Boolean = False): Integer; overload;
Function DecodedLength_Base64(const Str: String; Header: Boolean; PaddingChar: Char): Integer; overload;
Function AnsiDecodedLength_Base64(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): Integer; overload;
Function WideDecodedLength_Base64(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): Integer; overload;

Function DecodedLength_Base85(const Str: String; Header: Boolean = False): Integer; overload;
Function AnsiDecodedLength_Base85(const Str: AnsiString; Header: Boolean = False): Integer; overload;
Function WideDecodedLength_Base85(const Str: UnicodeString; Header: Boolean = False): Integer; overload;
Function DecodedLength_Base85(const Str: String; Header: Boolean; CompressionChar: Char): Integer; overload;
Function AnsiDecodedLength_Base85(const Str: AnsiString; Header: Boolean; CompressionChar: AnsiChar): Integer; overload;
Function WideDecodedLength_Base85(const Str: UnicodeString; Header: Boolean; CompressionChar: UnicodeChar): Integer; overload;

{------------------------------------------------------------------------------}

Function Encode_Base2(Data: Pointer; Size: Integer; Reversed: Boolean = False): String; overload;
Function AnsiEncode_Base2(Data: Pointer; Size: Integer; Reversed: Boolean = False): AnsiString; overload;
Function WideEncode_Base2(Data: Pointer; Size: Integer; Reversed: Boolean = False): UnicodeString; overload;

Function Encode_Base2(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of Char): String; overload;
Function AnsiEncode_Base2(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of AnsiChar): AnsiString; overload;
Function WideEncode_Base2(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of UnicodeChar): UnicodeString; overload;


Function Encode_Base8(Data: Pointer; Size: Integer; Reversed: Boolean = False; Padding: Boolean = True): String; overload;
Function AnsiEncode_Base8(Data: Pointer; Size: Integer; Reversed: Boolean = False; Padding: Boolean = True): AnsiString; overload;
Function WideEncode_Base8(Data: Pointer; Size: Integer; Reversed: Boolean = False; Padding: Boolean = True): UnicodeString; overload;

Function Encode_Base8(Data: Pointer; Size: Integer; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of Char; PaddingChar: Char): String; overload;
Function AnsiEncode_Base8(Data: Pointer; Size: Integer; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of AnsiChar; PaddingChar: AnsiChar): AnsiString; overload;
Function WideEncode_Base8(Data: Pointer; Size: Integer; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): UnicodeString; overload;


Function Encode_Base10(Data: Pointer; Size: Integer; Reversed: Boolean = False): String; overload;
Function AnsiEncode_Base10(Data: Pointer; Size: Integer; Reversed: Boolean = False): AnsiString; overload;
Function WideEncode_Base10(Data: Pointer; Size: Integer; Reversed: Boolean = False): UnicodeString; overload;

Function Encode_Base10(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of Char): String; overload;
Function AnsiEncode_Base10(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of AnsiChar): AnsiString; overload;
Function WideEncode_Base10(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of UnicodeChar): UnicodeString; overload;


Function Encode_Base16(Data: Pointer; Size: Integer; Reversed: Boolean = False): String; overload;
Function AnsiEncode_Base16(Data: Pointer; Size: Integer; Reversed: Boolean = False): AnsiString; overload;
Function WideEncode_Base16(Data: Pointer; Size: Integer; Reversed: Boolean = False): UnicodeString; overload;

Function Encode_Base16(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of Char): String; overload;
Function AnsiEncode_Base16(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of AnsiChar): AnsiString; overload;
Function WideEncode_Base16(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of UnicodeChar): UnicodeString; overload;

Function Encode_Hexadecimal(Data: Pointer; Size: Integer; Reversed: Boolean = False): String;
Function AnsiEncode_Hexadecimal(Data: Pointer; Size: Integer; Reversed: Boolean = False): AnsiString;
Function WideEncode_Hexadecimal(Data: Pointer; Size: Integer; Reversed: Boolean = False): UnicodeString;

{------------------------------------------------------------------------------}

Function Decode_Base2(const Str: String; out Size: Integer; Reversed: Boolean = False): Pointer; overload;
Function AnsiDecode_Base2(const Str: AnsiString; out Size: Integer; Reversed: Boolean = False): Pointer; overload;
Function WideDecode_Base2(const Str: UnicodeString; out Size: Integer; Reversed: Boolean = False): Pointer; overload;

Function Decode_Base2(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer; overload;
Function AnsiDecode_Base2(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer; overload;
Function WideDecode_Base2(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer; overload;

Function Decode_Base2(const Str: String; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of Char): Pointer; overload;
Function AnsiDecode_Base2(const Str: AnsiString; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Pointer; overload;
Function WideDecode_Base2(const Str: UnicodeString; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of WideChar): Pointer; overload;

Function Decode_Base2(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of Char): Integer; overload;
Function AnsiDecode_Base2(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Integer; overload;
Function WideDecode_Base2(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of WideChar): Integer; overload;


Function Decode_Base8(const Str: String; out Size: Integer; Reversed: Boolean = False): Pointer; overload;
Function AnsiDecode_Base8(const Str: AnsiString; out Size: Integer; Reversed: Boolean = False): Pointer; overload;
Function WideDecode_Base8(const Str: UnicodeString; out Size: Integer; Reversed: Boolean = False): Pointer; overload;

Function Decode_Base8(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer; overload;
Function AnsiDecode_Base8(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer; overload;
Function WideDecode_Base8(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer; overload;

Function Decode_Base8(const Str: String; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of Char; PaddingChar: Char): Pointer; overload;
Function AnsiDecode_Base8(const Str: AnsiString; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of AnsiChar; PaddingChar: AnsiChar): Pointer; overload;
Function WideDecode_Base8(const Str: UnicodeString; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): Pointer; overload;

Function Decode_Base8(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of Char; PaddingChar: Char): Integer; overload;
Function AnsiDecode_Base8(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of AnsiChar; PaddingChar: AnsiChar): Integer; overload;
Function WideDecode_Base8(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): Integer; overload;


Function Decode_Base10(const Str: String; out Size: Integer; Reversed: Boolean = False): Pointer; overload;
Function AnsiDecode_Base10(const Str: AnsiString; out Size: Integer; Reversed: Boolean = False): Pointer; overload;
Function WideDecode_Base10(const Str: UnicodeString; out Size: Integer; Reversed: Boolean = False): Pointer; overload;

Function Decode_Base10(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer; overload;
Function AnsiDecode_Base10(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer; overload;
Function WideDecode_Base10(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer; overload;

Function Decode_Base10(const Str: String; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of Char): Pointer; overload;
Function AnsiDecode_Base10(const Str: AnsiString; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Pointer; overload;
Function WideDecode_Base10(const Str: UnicodeString; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of UnicodeChar): Pointer; overload;

Function Decode_Base10(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of Char): Integer; overload;
Function AnsiDecode_Base10(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Integer; overload;
Function WideDecode_Base10(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of UnicodeChar): Integer; overload;


Function Decode_Base16(const Str: String; out Size: Integer; Reversed: Boolean = False): Pointer; overload;
Function AnsiDecode_Base16(const Str: AnsiString; out Size: Integer; Reversed: Boolean = False): Pointer; overload;
Function WideDecode_Base16(const Str: UnicodeString; out Size: Integer; Reversed: Boolean = False): Pointer; overload;

Function Decode_Base16(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer; overload;
Function AnsiDecode_Base16(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer; overload;
Function WideDecode_Base16(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer; overload;

Function Decode_Base16(const Str: String; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of Char): Pointer; overload;
Function AnsiDecode_Base16(const Str: AnsiString; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Pointer; overload;
Function WideDecode_Base16(const Str: UnicodeString; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of UnicodeChar): Pointer; overload;

Function Decode_Base16(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of Char): Integer; overload;
Function AnsiDecode_Base16(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Integer; overload;
Function WideDecode_Base16(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of UnicodeChar): Integer; overload;

Function Decode_Hexadecimal(const Str: String; out Size: Integer; Reversed: Boolean = False): Pointer; overload;
Function AnsiDecode_Hexadecimal(const Str: AnsiString; out Size: Integer; Reversed: Boolean = False): Pointer; overload;
Function WideDecode_Hexadecimal(const Str: UnicodeString; out Size: Integer; Reversed: Boolean = False): Pointer; overload;

Function Decode_Hexadecimal(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer; overload;
Function AnsiDecode_Hexadecimal(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer; overload;
Function WideDecode_Hexadecimal(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer; overload;


implementation

uses
  SysUtils, Math;

{$MESSAGE 'temporary'}
const
  headerlength = 4;
  EncodingHexadecimal = '$';

  Coefficients_Base10: Array[1..3] of Word = (100,10,1);
  Coefficients_Base85: Array[1..5] of LongWord = (52200625,614125,7225,85,1);

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
  raise Exception.CreateFmt('Decoding[base%d]: Output buffer too small (%d, required %d).',[Base,Size,Required]);
end;

{------------------------------------------------------------------------------}

Function AnsiTableIndex(const aChar: AnsiChar; const Table: Array of AnsiChar; Base: Integer): Byte;
begin
For Result := Low(Table) to High(Table) do
  If Table[Result] = aChar then Exit;
raise Exception.CreateFmt('AnsiTableIndex[base%d]: Invalid character "%s" (#%d).',[Base,aChar,Ord(aChar)]);
end;

{------------------------------------------------------------------------------}

Function WideTableIndex(const aChar: WideChar; const Table: Array of WideChar; Base: Integer): Byte;
begin
For Result := Low(Table) to High(Table) do
  If Table[Result] = aChar then Exit;
raise Exception.CreateFmt('WideTableIndex[base%d]: Invalid character "%s" (#%d).',[Base,aChar,Ord(aChar)]);
end;

{------------------------------------------------------------------------------}

Function AnsiCountPadding(Str: AnsiString; PaddingChar: AnsiChar): Integer;
var
  i:  Integer;
begin
Result := 0;
For i := Length(Str) downto 1 do
  If Str[i] = PaddingChar then Inc(Result)
    else Break;
end;

{------------------------------------------------------------------------------}

Function WideCountPadding(Str: UnicodeString; PaddingChar: WideChar): Integer;
var
  i:  Integer;
begin
Result := 0;
For i := Length(Str) downto 1 do
  If Str[i] = PaddingChar then Inc(Result)
    else Break;
end;

{------------------------------------------------------------------------------}

Function AnsiCountChars(Str: AnsiString; Character: AnsiChar): Integer;
var
  i: Integer;
begin
Result := 0;
For i := 1 to Length(Str) do
  If Str[i] = Character then Inc(Result);
end;

{------------------------------------------------------------------------------}

Function WideCountChars(Str: UnicodeString; Character: UnicodeChar): Integer;
var
  i: Integer;
begin
Result := 0;
For i := 1 to Length(Str) do
  If Str[i] = Character then Inc(Result);
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
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Base8(DataSize: Integer; Header: Boolean = False; Padding: Boolean = True): Integer;
begin
If Padding then Result := Ceil(DataSize / 3) * 8
  else Result := Ceil(DataSize * (8/3));
If Header then Result := Result + HeaderLength;
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Base10(DataSize: Integer; Header: Boolean = False): Integer;
begin
Result := DataSize * 3;
If Header then Result := Result + HeaderLength;
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Number(DataSize: Integer; Header: Boolean = False): Integer;
begin
Result := EncodedLength_Base10(DataSize,Header);
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Base16(DataSize: Integer; Header: Boolean = False): Integer;
begin
Result := DataSize * 2;
If Header then Result := Result + HeaderLength;
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Hexadecimal(DataSize: Integer; Header: Boolean = False): Integer;
begin
Result := DataSize * 2;
If Header then Result := Result + Length(EncodingHexadecimal);
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Base32(DataSize: Integer; Header: Boolean = False; Padding: Boolean = True): Integer;
begin
If Padding then Result := Ceil(DataSize / 5) * 8
  else Result := Ceil(DataSize * (8 / 5));
If Header then Result := Result + HeaderLength;
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Base32Hex(DataSize: Integer; Header: Boolean = False; Padding: Boolean = True): Integer;
begin
Result := EncodedLength_Base32(DataSize,Header,Padding);
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Base64(DataSize: Integer; Header: Boolean = False; Padding: Boolean = True): Integer;
begin
If Padding then Result := Ceil(DataSize / 3) * 4
  else Result := Ceil(DataSize * (4 / 3));
If Header then Result := Result + HeaderLength;
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Base85(DataSize: Integer; Header: Boolean = False; Trim: Boolean = False): Integer;
{$MESSAGE 'Implement compression count.'}
begin
If Trim then Result := Ceil(DataSize / 4) + DataSize
  else Result := Ceil(DataSize / 4) * 5;
If Header then Result := Result + HeaderLength;
If Result < 0 then Result := 0;
end;

{==============================================================================}
{------------------------------------------------------------------------------}
{    Functions calculating size of encoded data from length of encoded text    }
{------------------------------------------------------------------------------}
{==============================================================================}

Function DecodedLength_Base2(const Str: String; Header: Boolean = False): Integer;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base2(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base2(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base2(const Str: AnsiString; Header: Boolean = False): Integer;
begin
If Header then Result := (Length(Str) - HeaderLength) div 8
  else Result := Length(Str) div 8;
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base2(const Str: UnicodeString; Header: Boolean = False): Integer;
begin
If Header then Result := (Length(Str) - HeaderLength) div 8
  else Result := Length(Str) div 8;
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base8(const Str: String; Header: Boolean = False): Integer;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base8(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base8(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base8(const Str: AnsiString; Header: Boolean = False): Integer;
begin
Result := AnsiDecodedLength_Base8(Str,Header,AnsiPaddingChar_Base8);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base8(const Str: UnicodeString; Header: Boolean = False): Integer;
begin
Result := WideDecodedLength_Base8(Str,Header,WidePaddingChar_Base8);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base8(const Str: String; Header: Boolean; PaddingChar: Char): Integer;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base8(Str,Header,PaddingChar);
{$ELSE}
Result := AnsiDecodedLength_Base8(Str,Header,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base8(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): Integer;
begin
If Header then Result := Floor((((Length(Str) - HeaderLength) - AnsiCountPadding(Str,PaddingChar)) / 8) * 3)
  else Result := Floor(((Length(Str) - AnsiCountPadding(Str,PaddingChar)) / 8) * 3);
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base8(const Str: UnicodeString; Header: Boolean; PaddingChar: WideChar): Integer;
begin
If Header then Result := Floor((((Length(Str) - HeaderLength) - WideCountPadding(Str,PaddingChar)) / 8) * 3)
  else Result := Floor(((Length(Str) - WideCountPadding(Str,PaddingChar)) / 8) * 3);
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base10(const Str: String; Header: Boolean = False): Integer;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base10(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base10(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base10(const Str: AnsiString; Header: Boolean = False): Integer;
begin
If Header then Result := (Length(Str) - HeaderLength) div 3
  else Result := Length(Str) div 3;
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base10(const Str: UnicodeString; Header: Boolean = False): Integer;
begin
If Header then Result := (Length(Str) - HeaderLength) div 3
  else Result := Length(Str) div 3;
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Number(const Str: String; Header: Boolean = False): Integer;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Number(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Number(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Number(const Str: AnsiString; Header: Boolean = False): Integer;
begin
Result := AnsiDecodedLength_Base10(Str,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Number(const Str: UnicodeString; Header: Boolean = False): Integer;
begin
Result := WideDecodedLength_Base10(Str,Header);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base16(const Str: String; Header: Boolean = False): Integer;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base16(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base16(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base16(const Str: AnsiString; Header: Boolean = False): Integer;
begin
If Header then Result := (Length(Str) - HeaderLength) div 2
  else Result := Length(Str) div 2;
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base16(const Str: UnicodeString; Header: Boolean = False): Integer;
begin
If Header then Result := (Length(Str) - HeaderLength) div 2
  else Result := Length(Str) div 2;
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Hexadecimal(const Str: String; Header: Boolean = False): Integer;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Hexadecimal(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Hexadecimal(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Hexadecimal(const Str: AnsiString; Header: Boolean = False): Integer;
begin
If Header then Result := (Length(Str) - Length(EncodingHexadecimal)) div 2
  else Result := Length(Str) div 2;
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Hexadecimal(const Str: UnicodeString; Header: Boolean = False): Integer;
begin
If Header then Result := (Length(Str) - Length(EncodingHexadecimal)) div 2
  else Result := Length(Str) div 2;
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base32(const Str: String; Header: Boolean = False): Integer;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base32(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base32(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base32(const Str: AnsiString; Header: Boolean = False): Integer;
begin
Result := AnsiDecodedLength_Base32(Str,Header,AnsiPaddingChar_Base32);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base32(const Str: UnicodeString; Header: Boolean = False): Integer;
begin
Result := WideDecodedLength_Base32(Str,Header,WidePaddingChar_Base32);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base32(const Str: String; Header: Boolean; PaddingChar: Char): Integer;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base32(Str,Header,PaddingChar);
{$ELSE}
Result := AnsiDecodedLength_Base32(Str,Header,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base32(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): Integer;
begin
If Header then Result := Floor((((Length(Str) - HeaderLength) - AnsiCountPadding(Str,PaddingChar)) / 8) * 5)
  else Result := Floor(((Length(Str) - AnsiCountPadding(Str,PaddingChar)) / 8) * 5);
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base32(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): Integer;
begin
If Header then Result := Floor((((Length(Str) - HeaderLength) - WideCountPadding(Str,PaddingChar)) / 8) * 5)
  else Result := Floor(((Length(Str) - WideCountPadding(Str,PaddingChar)) / 8) * 5);
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base32Hex(const Str: String; Header: Boolean = False): Integer;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base32Hex(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base32Hex(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base32Hex(const Str: AnsiString; Header: Boolean = False): Integer;
begin
Result := AnsiDecodedLength_Base32Hex(Str,Header,AnsiPaddingChar_Base32Hex);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base32Hex(const Str: UnicodeString; Header: Boolean = False): Integer;
begin
Result := WideDecodedLength_Base32Hex(Str,Header,WidePaddingChar_Base32Hex);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base32Hex(const Str: String; Header: Boolean; PaddingChar: Char): Integer;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base32Hex(Str,Header,PaddingChar);
{$ELSE}
Result := AnsiDecodedLength_Base32Hex(Str,Header,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base32Hex(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): Integer;
begin
Result := AnsiDecodedLength_Base32(Str,Header,PaddingChar);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base32Hex(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): Integer;
begin
Result := WideDecodedLength_Base32(Str,Header,PaddingChar);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base64(const Str: String; Header: Boolean = False): Integer;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base64(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base64(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base64(const Str: AnsiString; Header: Boolean = False): Integer;
begin
Result := AnsiDecodedLength_Base64(Str,Header,AnsiPaddingChar_Base64);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base64(const Str: UnicodeString; Header: Boolean = False): Integer;
begin
Result := WideDecodedLength_Base64(Str,Header,WidePaddingChar_Base64);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base64(const Str: String; Header: Boolean; PaddingChar: Char): Integer;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base64(Str,Header,PaddingChar);
{$ELSE}
Result := AnsiDecodedLength_Base64(Str,Header,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base64(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): Integer;
begin
If Header then Result := Floor((((Length(Str) - HeaderLength) - AnsiCountPadding(Str,PaddingChar)) / 4) * 3)
  else Result := Floor(((Length(Str) - AnsiCountPadding(Str,PaddingChar)) / 4) * 3);
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base64(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): Integer;
begin
If Header then Result := Floor((((Length(Str) - HeaderLength) - WideCountPadding(Str,PaddingChar)) / 4) * 3)
  else Result := Floor(((Length(Str) - WideCountPadding(Str,PaddingChar)) / 4) * 3);
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base85(const Str: String; Header: Boolean = False): Integer;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base85(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base85(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base85(const Str: AnsiString; Header: Boolean = False): Integer;
begin
Result := AnsiDecodedLength_Base85(Str,Header,AnsiCompressionChar_Base85);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base85(const Str: UnicodeString; Header: Boolean = False): Integer;
begin
Result := WideDecodedLength_Base85(Str,Header,WideCompressionChar_Base85);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base85(const Str: String; Header: Boolean; CompressionChar: Char): Integer;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base85(Str,Header,CompressionChar);
{$ELSE}
Result := AnsiDecodedLength_Base85(Str,Header,CompressionChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base85(const Str: AnsiString; Header: Boolean; CompressionChar: AnsiChar): Integer;
var
  UncompressedLength: Integer;
begin
UncompressedLength := Length(Str) + (AnsiCountChars(Str,CompressionChar) * 4);
If Header then Result := (UncompressedLength - HeaderLength) - Ceil((UncompressedLength - HeaderLength) / 5)
  else Result := UncompressedLength - Ceil(UncompressedLength / 5);
If Result < 0 then Result := 0;
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base85(const Str: UnicodeString; Header: Boolean; CompressionChar: UnicodeChar): Integer;
var
  UncompressedLength: Integer;
begin
UncompressedLength := Length(Str) + (WideCountChars(Str,CompressionChar) * 4);
If Header then Result := (UncompressedLength - HeaderLength) - Ceil((UncompressedLength - HeaderLength) / 5)
  else Result := UncompressedLength - Ceil(UncompressedLength / 5);
If Result < 0 then Result := 0;
end;

{==============================================================================}
{------------------------------------------------------------------------------}
{    Encoding functions                                                        }
{------------------------------------------------------------------------------}
{==============================================================================}

Function Encode_Base2(Data: Pointer; Size: Integer; Reversed: Boolean = False): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base2(Data,Size,Reversed);
{$ELSE}
Result := AnsiEncode_Base2(Data,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base2(Data: Pointer; Size: Integer; Reversed: Boolean = False): AnsiString;
begin
Result := AnsiEncode_Base2(Data,Size,Reversed,AnsiEncodingTable_Base2);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base2(Data: Pointer; Size: Integer; Reversed: Boolean = False): UnicodeString;
begin
Result := WideEncode_Base2(Data,Size,Reversed,WideEncodingTable_Base2);
end;

{------------------------------------------------------------------------------}

Function Encode_Base2(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of Char): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base2(Data,Size,Reversed,EncodingTable);
{$ELSE}
Result := AnsiEncode_Base2(Data,Size,Reversed,EncodingTable);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base2(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of AnsiChar): AnsiString;
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

Function WideEncode_Base2(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of UnicodeChar): UnicodeString;
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

Function Encode_Base8(Data: Pointer; Size: Integer; Reversed: Boolean = False; Padding: Boolean = True): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base8(Data,Size,Reversed,Padding);
{$ELSE}
Result := AnsiEncode_Base8(Data,Size,Reversed,Padding);
{$ENDIF}
end;
 
{------------------------------------------------------------------------------}

Function AnsiEncode_Base8(Data: Pointer; Size: Integer; Reversed: Boolean = False; Padding: Boolean = True): AnsiString;
begin
Result := AnsiEncode_Base8(Data,Size,Reversed,Padding,AnsiEncodingTable_Base8,AnsiPaddingChar_Base8);
end;
 
{------------------------------------------------------------------------------}

Function WideEncode_Base8(Data: Pointer; Size: Integer; Reversed: Boolean = False; Padding: Boolean = True): UnicodeString;
begin
Result := WideEncode_Base8(Data,Size,Reversed,Padding,WideEncodingTable_Base8,WidePaddingChar_Base8);
end;

{------------------------------------------------------------------------------}

Function Encode_Base8(Data: Pointer; Size: Integer; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of Char; PaddingChar: Char): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base8(Data,Size,Reversed,Padding,EncodingTable,PaddingChar);
{$ELSE}
Result := AnsiEncode_Base8(Data,Size,Reversed,Padding,EncodingTable,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base8(Data: Pointer; Size: Integer; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of AnsiChar; PaddingChar: AnsiChar): AnsiString;
var
  Buffer:         Byte;
  i:              Integer;
  Remainder:      Byte;
  RemainderBits:  Integer;
  ResultPosition: Integer;
begin
ResolveDataPointer(Data,Reversed,Size);
SetLength(Result,EncodedLength_Base8(Size,False,Padding));
Remainder := 0;
RemainderBits := 0;
ResultPosition := 1;
For i := 0 to Pred(Size) do
  begin
    Buffer := PByte(Data)^;
    case RemainderBits of
      0:  begin
            Result[ResultPosition] := EncodingTable[(Buffer and $E0) shr 5];
            Result[ResultPosition + 1] := EncodingTable[(Buffer and $1C) shr 2];
            Inc(ResultPosition,2);
            Remainder := Buffer and $03;
            RemainderBits := 2;
          end;
      1:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 2) or ((Buffer and $C0) shr 6)];
            Result[ResultPosition + 1] := EncodingTable[(Buffer and $38) shr 3];
            Result[ResultPosition + 2] := EncodingTable[Buffer and $07];
            Inc(ResultPosition,3);
            Remainder := 0;
            RemainderBits := 0;
          end;
      2:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 1) or ((Buffer and $80) shr 7)];
            Result[ResultPosition + 1] := EncodingTable[(Buffer and $70) shr 4];
            Result[ResultPosition + 2] := EncodingTable[(Buffer and $0E) shr 1];
            Inc(ResultPosition,3);
            Remainder := Buffer and $01;
            RemainderBits := 1;
          end;
    else
      raise Exception.CreateFmt('AnsiEncode_Base8: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    AdvanceDataPointer(Data,Reversed);
  end;
case RemainderBits of
  1:  Result[ResultPosition] := EncodingTable[Remainder shl 2];
  2:  Result[ResultPosition] := EncodingTable[Remainder shl 1];
end;
Inc(ResultPosition);
If Padding then
  For i := ResultPosition to Length(Result) do Result[i] := PaddingChar;
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base8(Data: Pointer; Size: Integer; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): UnicodeString;
var
  Buffer:         Byte;
  i:              Integer;
  Remainder:      Byte;
  RemainderBits:  Integer;
  ResultPosition: Integer;
begin
ResolveDataPointer(Data,Reversed,Size);
SetLength(Result,EncodedLength_Base8(Size,False,Padding));
Remainder := 0;
RemainderBits := 0;
ResultPosition := 1;
For i := 0 to Pred(Size) do
  begin
    Buffer := PByte(Data)^;
    case RemainderBits of
      0:  begin
            Result[ResultPosition] := EncodingTable[(Buffer and $E0) shr 5];
            Result[ResultPosition + 1] := EncodingTable[(Buffer and $1C) shr 2];
            Inc(ResultPosition,2);
            Remainder := Buffer and $03;
            RemainderBits := 2;
          end;
      1:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 2) or ((Buffer and $C0) shr 6)];
            Result[ResultPosition + 1] := EncodingTable[(Buffer and $38) shr 3];
            Result[ResultPosition + 2] := EncodingTable[Buffer and $07];
            Inc(ResultPosition,3);
            Remainder := 0;
            RemainderBits := 0;
          end;
      2:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 1) or ((Buffer and $80) shr 7)];
            Result[ResultPosition + 1] := EncodingTable[(Buffer and $70) shr 4];
            Result[ResultPosition + 2] := EncodingTable[(Buffer and $0E) shr 1];
            Inc(ResultPosition,3);
            Remainder := Buffer and $01;
            RemainderBits := 1;
          end;
    else
      raise Exception.CreateFmt('WideEncode_Base8: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    AdvanceDataPointer(Data,Reversed);
  end;
case RemainderBits of
  1:  Result[ResultPosition] := EncodingTable[Remainder shl 2];
  2:  Result[ResultPosition] := EncodingTable[Remainder shl 1];
end;
Inc(ResultPosition);
If Padding then
  For i := ResultPosition to Length(Result) do Result[i] := PaddingChar;
end;

{==============================================================================}

Function Encode_Base10(Data: Pointer; Size: Integer; Reversed: Boolean = False): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base10(Data,Size,Reversed);
{$ELSE}
Result := AnsiEncode_Base10(Data,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base10(Data: Pointer; Size: Integer; Reversed: Boolean = False): AnsiString;
begin
Result := AnsiEncode_Base10(Data,Size,Reversed,AnsiEncodingTable_Base10);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base10(Data: Pointer; Size: Integer; Reversed: Boolean = False): UnicodeString;
begin
Result := WideEncode_Base10(Data,Size,Reversed,WideEncodingTable_Base10);
end;

{------------------------------------------------------------------------------}

Function Encode_Base10(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of Char): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base10(Data,Size,Reversed,EncodingTable);
{$ELSE}
Result := AnsiEncode_Base10(Data,Size,Reversed,EncodingTable);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base10(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of AnsiChar): AnsiString;
var
  Buffer: Byte;
  i,j:    Integer;
begin
ResolveDataPointer(Data,Reversed,Size);
SetLength(Result,EncodedLength_Base10(Size));
For i := 0 to Pred(Size) do
  begin
    Buffer := PByte(Data)^;
    For j := 1 to 3 do
      begin
        Result[(i * 3) + j] := EncodingTable[Buffer div Coefficients_Base10[j]];
        Buffer := Buffer mod Coefficients_Base10[j];
      end;
    AdvanceDataPointer(Data,Reversed);
  end;
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base10(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of UnicodeChar): UnicodeString;
var
  Buffer: Byte;
  i,j:    Integer;
begin
ResolveDataPointer(Data,Reversed,Size);
SetLength(Result,EncodedLength_Base10(Size));
For i := 0 to Pred(Size) do
  begin
    Buffer := PByte(Data)^;
    For j := 1 to 3 do
      begin
        Result[(i * 3) + j] := EncodingTable[Buffer div Coefficients_Base10[j]];
        Buffer := Buffer mod Coefficients_Base10[j];
      end;
    AdvanceDataPointer(Data,Reversed);
  end;
end;

{==============================================================================}

Function Encode_Base16(Data: Pointer; Size: Integer; Reversed: Boolean = False): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base16(Data,Size,Reversed);
{$ELSE}
Result := AnsiEncode_Base16(Data,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base16(Data: Pointer; Size: Integer; Reversed: Boolean = False): AnsiString;
begin
Result := AnsiEncode_Base16(Data,Size,Reversed,AnsiEncodingTable_Base16);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base16(Data: Pointer; Size: Integer; Reversed: Boolean = False): UnicodeString;
begin
Result := WideEncode_Base16(Data,Size,Reversed,WideEncodingTable_Base16);
end;

{------------------------------------------------------------------------------}

Function Encode_Base16(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of Char): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base16(Data,Size,Reversed,EncodingTable);
{$ELSE}
Result := AnsiEncode_Base16(Data,Size,Reversed,EncodingTable);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base16(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of AnsiChar): AnsiString;
var
  i:  Integer;
begin
ResolveDataPointer(Data,Reversed,Size);
SetLength(Result,EncodedLength_Base16(Size));
For i := 0 to Pred(Size) do
  begin
    Result[(i * 2) + 1] := EncodingTable[PByte(Data)^ shr 4];
    Result[(i * 2) + 2] := EncodingTable[PByte(Data)^ and $0F];
    AdvanceDataPointer(Data,Reversed);
  end;
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base16(Data: Pointer; Size: Integer; Reversed: Boolean; const EncodingTable: Array of UnicodeChar): UnicodeString;
var
  i:  Integer;
begin
ResolveDataPointer(Data,Reversed,Size);
SetLength(Result,EncodedLength_Base16(Size));
For i := 0 to Pred(Size) do
  begin
    Result[(i * 2) + 1] := EncodingTable[PByte(Data)^ shr 4];
    Result[(i * 2) + 2] := EncodingTable[PByte(Data)^ and $0F];
    AdvanceDataPointer(Data,Reversed);
  end;
end;

{------------------------------------------------------------------------------}

Function Encode_Hexadecimal(Data: Pointer; Size: Integer; Reversed: Boolean = False): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Hexadecimal(Data,Size,Reversed);
{$ELSE}
Result := AnsiEncode_Hexadecimal(Data,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Hexadecimal(Data: Pointer; Size: Integer; Reversed: Boolean = False): AnsiString;
begin
Result := AnsiEncode_Base16(Data,Size,Reversed,AnsiEncodingTable_Hexadecimal);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Hexadecimal(Data: Pointer; Size: Integer; Reversed: Boolean = False): UnicodeString;
begin
Result := WideEncode_Base16(Data,Size,Reversed,WideEncodingTable_Hexadecimal);
end;

{==============================================================================}
{------------------------------------------------------------------------------}
{    Decoding functions                                                        }
{------------------------------------------------------------------------------}
{==============================================================================}

Function Decode_Base2(const Str: String; out Size: Integer; Reversed: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base2(Str,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base2(Str,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base2(const Str: AnsiString; out Size: Integer; Reversed: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base2(Str,Size,Reversed,AnsiEncodingTable_Base2);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base2(const Str: UnicodeString; out Size: Integer; Reversed: Boolean = False): Pointer;
begin
Result := WideDecode_Base2(Str,Size,Reversed,WideEncodingTable_Base2);
end;

{------------------------------------------------------------------------------}

Function Decode_Base2(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base2(Str,Ptr,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base2(Str,Ptr,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base2(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer;
begin
Result := AnsiDecode_Base2(Str,Ptr,Size,Reversed,AnsiEncodingTable_Base2);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base2(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer;
begin
Result := WideDecode_Base2(Str,Ptr,Size,Reversed,WideEncodingTable_Base2);
end;

{------------------------------------------------------------------------------}

Function Decode_Base2(const Str: String; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of Char): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base2(Str,Size,Reversed,DecodingTable);
{$ELSE}
Result := AnsiDecode_Base2(Str,Size,Reversed,DecodingTable);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base2(const Str: AnsiString; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Pointer;
begin
Size := AnsiDecodedLength_Base2(Str);
Result := AllocMem(Size);
try
  Size := AnsiDecode_Base2(Str,Result,Size,Reversed,DecodingTable);
except
  FreeMem(Result,Size);
  Result := nil;
  Size := 0;
  raise;
end;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base2(const Str: UnicodeString; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of WideChar): Pointer;
begin
Size := WideDecodedLength_Base2(Str);
Result := AllocMem(Size);
try
  Size := WideDecode_Base2(Str,Result,Size,Reversed,DecodingTable);
except
  FreeMem(Result,Size);
  Result := nil;
  Size := 0;
  raise;
end;
end;

{------------------------------------------------------------------------------}

Function Decode_Base2(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of Char): Integer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base2(Str,Ptr,Size,Reversed,DecodingTable);
{$ELSE}
Result := AnsiDecode_Base2(Str,Ptr,Size,Reversed,DecodingTable);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base2(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Integer;
var
  Buffer: Byte;
  i,j:    Integer;
begin
Result := AnsiDecodedLength_Base2(Str);
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

Function WideDecode_Base2(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of WideChar): Integer;
var
  Buffer: Byte;
  i,j:    Integer;
begin
Result := WideDecodedLength_Base2(Str);
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

{==============================================================================}

Function Decode_Base8(const Str: String; out Size: Integer; Reversed: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base8(Str,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base8(Str,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base8(const Str: AnsiString; out Size: Integer; Reversed: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base8(Str,Size,Reversed,AnsiEncodingTable_Base8,AnsiPaddingChar_Base8);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base8(const Str: UnicodeString; out Size: Integer; Reversed: Boolean = False): Pointer; 
begin
Result := WideDecode_Base8(Str,Size,Reversed,WideEncodingTable_Base8,WidePaddingChar_Base8);
end;

{------------------------------------------------------------------------------}

Function Decode_Base8(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer; 
begin
{$IFDEF Unicode}
Result := WideDecode_Base8(Str,Ptr,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base8(Str,Ptr,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base8(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer; 
begin
Result := AnsiDecode_Base8(Str,Ptr,Size,Reversed,AnsiEncodingTable_Base8,AnsiPaddingChar_Base8);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base8(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer; 
begin
Result := WideDecode_Base8(Str,Ptr,Size,Reversed,WideEncodingTable_Base8,WidePaddingChar_Base8);
end;

{------------------------------------------------------------------------------}

Function Decode_Base8(const Str: String; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of Char; PaddingChar: Char): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base8(Str,Size,Reversed,DecodingTable,PaddingChar);
{$ELSE}
Result := AnsiDecode_Base8(Str,Size,Reversed,DecodingTable,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base8(const Str: AnsiString; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of AnsiChar; PaddingChar: AnsiChar): Pointer;
begin
Size := AnsiDecodedLength_Base8(Str,False,PaddingChar);
Result := AllocMem(Size);
try
  Size := AnsiDecode_Base8(Str,Result,Size,Reversed,DecodingTable,PaddingChar);
except
  FreeMem(Result,Size);
  Result := nil;
  Size := 0;
  raise;
end;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base8(const Str: UnicodeString; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): Pointer; 
begin
Size := WideDecodedLength_Base8(Str,False,PaddingChar);
Result := AllocMem(Size);
try
  Size := WideDecode_Base8(Str,Result,Size,Reversed,DecodingTable,PaddingChar);
except
  FreeMem(Result,Size);
  Result := nil;
  Size := 0;
  raise;
end;
end;

{------------------------------------------------------------------------------}

Function Decode_Base8(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of Char; PaddingChar: Char): Integer; 
begin
{$IFDEF Unicode}
Result := WideDecode_Base8(Str,Ptr,Size,Reversed,DecodingTable,PaddingChar);
{$ELSE}
Result := AnsiDecode_Base8(Str,Ptr,Size,Reversed,DecodingTable,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base8(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of AnsiChar; PaddingChar: AnsiChar): Integer; 
var
  Buffer:         Byte;
  i:              Integer;
  Remainder:      Byte;
  RemainderBits:  Integer;
  StrPosition:    Integer;
begin
Result := AnsiDecodedLength_Base8(Str,False,PaddingChar);
DecodeCheckSize(Size,Result,8);
ResolveDataPointer(Ptr,Reversed,Size);
Remainder := 0;
RemainderBits := 0;
StrPosition := 1;
For i := 0 to Pred(Result) do
  begin
    case RemainderBits of
      0:  begin
            Buffer := (AnsiTableIndex(Str[StrPosition],DecodingTable,8) shl 5) or
                      (AnsiTableIndex(Str[StrPosition + 1],DecodingTable,8) shl 2);
            Remainder := AnsiTableIndex(Str[StrPosition + 2],DecodingTable,8);
            Buffer := Buffer or (Remainder shr 1);
            Inc(StrPosition,3);
            Remainder := Remainder and $01;
            RemainderBits := 1;
          end;
      1:  begin
            Buffer := (Remainder shl 7) or (AnsiTableIndex(Str[StrPosition],DecodingTable,8) shl 4) or
                      (AnsiTableIndex(Str[StrPosition + 1],DecodingTable,8) shl 1);
            Remainder := AnsiTableIndex(Str[StrPosition + 2],DecodingTable,8);
            Buffer := Buffer or (Remainder shr 2);
            Inc(StrPosition,3);
            Remainder := Remainder and $03;
            RemainderBits := 2;
          end;
      2:  begin
            Buffer := (Remainder shl 6) or (AnsiTableIndex(Str[StrPosition],DecodingTable,8) shl 3) or
                      AnsiTableIndex(Str[StrPosition + 1],DecodingTable,8);
            Inc(StrPosition,2);
            Remainder := 0;
            RemainderBits := 0;
          end;
    else
      raise Exception.CreateFmt('AnsiDecode_Base8: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    PByte(Ptr)^ := Buffer;
    AdvanceDataPointer(Ptr,Reversed);
  end;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base8(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): Integer; 
var
  Buffer:         Byte;
  i:              Integer;
  Remainder:      Byte;
  RemainderBits:  Integer;
  StrPosition:    Integer;
begin
Result := WideDecodedLength_Base8(Str,False,PaddingChar);
DecodeCheckSize(Size,Result,8);
ResolveDataPointer(Ptr,Reversed,Size);
Remainder := 0;
RemainderBits := 0;
StrPosition := 1;
For i := 0 to Pred(Result) do
  begin
    case RemainderBits of
      0:  begin
            Buffer := (WideTableIndex(Str[StrPosition],DecodingTable,8) shl 5) or
                      (WideTableIndex(Str[StrPosition + 1],DecodingTable,8) shl 2);
            Remainder := WideTableIndex(Str[StrPosition + 2],DecodingTable,8);
            Buffer := Buffer or (Remainder shr 1);
            Inc(StrPosition,3);
            Remainder := Remainder and $01;
            RemainderBits := 1;
          end;
      1:  begin
            Buffer := (Remainder shl 7) or (WideTableIndex(Str[StrPosition],DecodingTable,8) shl 4) or
                      (WideTableIndex(Str[StrPosition + 1],DecodingTable,8) shl 1);
            Remainder := WideTableIndex(Str[StrPosition + 2],DecodingTable,8);
            Buffer := Buffer or (Remainder shr 2);
            Inc(StrPosition,3);
            Remainder := Remainder and $03;
            RemainderBits := 2;
          end;
      2:  begin
            Buffer := (Remainder shl 6) or (WideTableIndex(Str[StrPosition],DecodingTable,8) shl 3) or
                      WideTableIndex(Str[StrPosition + 1],DecodingTable,8);
            Inc(StrPosition,2);
            Remainder := 0;
            RemainderBits := 0;
          end;
    else
      raise Exception.CreateFmt('WideDecode_Base8: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    PByte(Ptr)^ := Buffer;
    AdvanceDataPointer(Ptr,Reversed);
  end;
end;

{==============================================================================}

Function Decode_Base10(const Str: String; out Size: Integer; Reversed: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base10(Str,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base10(Str,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base10(const Str: AnsiString; out Size: Integer; Reversed: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base10(Str,Size,Reversed,AnsiEncodingTable_Base10);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base10(const Str: UnicodeString; out Size: Integer; Reversed: Boolean = False): Pointer;
begin
Result := WideDecode_Base10(Str,Size,Reversed,WideEncodingTable_Base10);
end;

{------------------------------------------------------------------------------}

Function Decode_Base10(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base10(Str,Ptr,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base10(Str,Ptr,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base10(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer;
begin
Result := AnsiDecode_Base10(Str,Ptr,Size,Reversed,AnsiEncodingTable_Base10);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base10(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer;
begin
Result := WideDecode_Base10(Str,Ptr,Size,Reversed,WideEncodingTable_Base10);
end;

{------------------------------------------------------------------------------}

Function Decode_Base10(const Str: String; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of Char): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base10(Str,Size,Reversed,DecodingTable);
{$ELSE}
Result := AnsiDecode_Base10(Str,Size,Reversed,DecodingTable);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base10(const Str: AnsiString; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Pointer;
begin
Size := AnsiDecodedLength_Base10(Str);
Result := AllocMem(Size);
try
  Size := AnsiDecode_Base10(Str,Result,Size,Reversed,DecodingTable);
except
  FreeMem(Result,Size);
  Result := nil;
  Size := 0;
  raise;
end;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base10(const Str: UnicodeString; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of UnicodeChar): Pointer;
begin
Size := WideDecodedLength_Base10(Str);
Result := AllocMem(Size);
try
  Size := WideDecode_Base10(Str,Result,Size,Reversed,DecodingTable);
except
  FreeMem(Result,Size);
  Result := nil;
  Size := 0;
  raise;
end;
end;

{------------------------------------------------------------------------------}

Function Decode_Base10(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of Char): Integer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base10(Str,Ptr,Size,Reversed,DecodingTable);
{$ELSE}
Result := AnsiDecode_Base10(Str,Ptr,Size,Reversed,DecodingTable);
{$ENDIF}
end;


{------------------------------------------------------------------------------}

Function AnsiDecode_Base10(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Integer;
var
  i:  Integer;
begin
Result := AnsiDecodedLength_Base10(Str);
DecodeCheckSize(Size,Result,10);
ResolveDataPointer(Ptr,Reversed,Size);
For i := 0 to Pred(Result) do
  begin
    PByte(Ptr)^ := AnsiTableIndex(Str[(i * 3) + 1],DecodingTable,10) * Coefficients_Base10[1] +
                   AnsiTableIndex(Str[(i * 3) + 2],DecodingTable,10) * Coefficients_Base10[2] +
                   AnsiTableIndex(Str[(i * 3) + 3],DecodingTable,10) * Coefficients_Base10[3];
    AdvanceDataPointer(Ptr,Reversed)
  end;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base10(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of UnicodeChar): Integer;
var
  i:  Integer;
begin
Result := WideDecodedLength_Base10(Str);
DecodeCheckSize(Size,Result,10);
ResolveDataPointer(Ptr,Reversed,Size);
For i := 0 to Pred(Result) do
  begin
    PByte(Ptr)^ := WideTableIndex(Str[(i * 3) + 1],DecodingTable,10) * Coefficients_Base10[1] +
                   WideTableIndex(Str[(i * 3) + 2],DecodingTable,10) * Coefficients_Base10[2] +
                   WideTableIndex(Str[(i * 3) + 3],DecodingTable,10) * Coefficients_Base10[3];
    AdvanceDataPointer(Ptr,Reversed)
  end;
end;

{==============================================================================}

Function Decode_Base16(const Str: String; out Size: Integer; Reversed: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base16(Str,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base16(Str,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base16(const Str: AnsiString; out Size: Integer; Reversed: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base16(Str,Size,Reversed,AnsiEncodingTable_Base16);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base16(const Str: UnicodeString; out Size: Integer; Reversed: Boolean = False): Pointer;
begin
Result := WideDecode_Base16(Str,Size,Reversed,WideEncodingTable_Base16);
end;

{------------------------------------------------------------------------------}

Function Decode_Base16(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base16(Str,Ptr,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base16(Str,Ptr,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base16(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer;
begin
Result := AnsiDecode_Base16(Str,Ptr,Size,Reversed,AnsiEncodingTable_Base16);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base16(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer;
begin
Result := WideDecode_Base16(Str,Ptr,Size,Reversed,WideEncodingTable_Base16);
end;

{------------------------------------------------------------------------------}

Function Decode_Base16(const Str: String; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of Char): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base16(Str,Size,Reversed,DecodingTable);
{$ELSE}
Result := AnsiDecode_Base16(Str,Size,Reversed,DecodingTable);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base16(const Str: AnsiString; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Pointer;
begin
Size := AnsiDecodedLength_Base16(Str);
Result := AllocMem(Size);
try
  Size := AnsiDecode_Base16(Str,Result,Size,Reversed,DecodingTable);
except
  FreeMem(Result,Size);
  Result := nil;
  Size := 0;
  raise;
end;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base16(const Str: UnicodeString; out Size: Integer; Reversed: Boolean; const DecodingTable: Array of UnicodeChar): Pointer;
begin
Size := WideDecodedLength_Base16(Str);
Result := AllocMem(Size);
try
  Size := WideDecode_Base16(Str,Result,Size,Reversed,DecodingTable);
except
  FreeMem(Result,Size);
  Result := nil;
  Size := 0;
  raise;
end;
end;

{------------------------------------------------------------------------------}

Function Decode_Base16(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of Char): Integer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base16(Str,Ptr,Size,Reversed,DecodingTable);
{$ELSE}
Result := AnsiDecode_Base16(Str,Ptr,Size,Reversed,DecodingTable);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base16(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Integer;
var
  i:  Integer;
begin
Result := AnsiDecodedLength_Base16(Str);
DecodeCheckSize(Size,Result,16);
ResolveDataPointer(Ptr,Reversed,Size);
For i := 0 to Pred(Result) do
  begin
    PByte(Ptr)^ := (AnsiTableIndex(Str[(i * 2) + 1],DecodingTable,16) shl 4) or
                   (AnsiTableIndex(Str[(i * 2) + 2],DecodingTable,16) and $0F);
    AdvanceDataPointer(Ptr,Reversed);
  end;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base16(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean; const DecodingTable: Array of UnicodeChar): Integer;
var
  i:  Integer;
begin
Result := WideDecodedLength_Base16(Str);
DecodeCheckSize(Size,Result,16);
ResolveDataPointer(Ptr,Reversed,Size);
For i := 0 to Pred(Result) do
  begin
    PByte(Ptr)^ := (WideTableIndex(Str[(i * 2) + 1],DecodingTable,16) shl 4) or
                   (WideTableIndex(Str[(i * 2) + 2],DecodingTable,16) and $0F);
    AdvanceDataPointer(Ptr,Reversed);
  end;
end;

{------------------------------------------------------------------------------}

Function Decode_Hexadecimal(const Str: String; out Size: Integer; Reversed: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Hexadecimal(Str,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Hexadecimal(Str,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Hexadecimal(const Str: AnsiString; out Size: Integer; Reversed: Boolean = False): Pointer;
begin
Size := AnsiDecodedLength_Hexadecimal(Str);
Result := AllocMem(Size);
try
  Size := AnsiDecode_Hexadecimal(Str,Result,Size,Reversed);
except
  FreeMem(Result,Size);
  Result := nil;
  Size := 0;
  raise;
end;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Hexadecimal(const Str: UnicodeString; out Size: Integer; Reversed: Boolean = False): Pointer;
begin
Size := WideDecodedLength_Hexadecimal(Str);
Result := AllocMem(Size);
try
  Size := WideDecode_Hexadecimal(Str,Result,Size,Reversed);
except
  FreeMem(Result,Size);
  Result := nil;
  Size := 0;
  raise;
end;
end;

{------------------------------------------------------------------------------}

Function Decode_Hexadecimal(const Str: String; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer;
begin
{$IFDEF Unicode}
Result := WideDecode_Hexadecimal(Str,Ptr,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Hexadecimal(Str,Ptr,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Hexadecimal(const Str: AnsiString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer;
begin
Result := AnsiDecode_Base16(Str,Ptr,Size,Reversed,AnsiEncodingTable_Hexadecimal);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Hexadecimal(const Str: UnicodeString; Ptr: Pointer; Size: Integer; Reversed: Boolean = False): Integer;
begin
Result := WideDecode_Base16(Str,Ptr,Size,Reversed,WideEncodingTable_Hexadecimal);
end;



end.
