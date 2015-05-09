{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Binary to text encodings

  ©2015 František Milt

  Version 1.0

  todo:
    - add ignoring of whitespaces in base85 decoding
    - reverse tables (decoding)
    - optimize use of strings (no Copy or concatenation)

  Notes:
    - Do not call EncodedLength function with Base85 encoding.
    - Hexadecimal encoding is always forward (ie. not reversed) when executed by
      a universal function, irrespective of selected setting.
    - Base16, Base32 nad Base64 encodings should be compliant with RFC 4648.
    - Base85 encoding is by-default using Z85 alphabet with undescore ("_", #95)
      as an all-zero-compression letter, but Ascii85 alphabet is provided too.  

===============================================================================}
unit BinTextEnc;

interface

uses
  SysUtils;

type
{$IFDEF x64}
  PtrInt  = Int64;
  PtrUInt = UInt64;
{$ELSE}
  PtrInt  = LongInt;
  PtrUInt = LongWord;
{$ENDIF}

  TDataSize = PtrUInt;
  TStrSize  = PtrInt;

{$IF not Defined(FPC) and not Defined(Unicode)}
  UnicodeChar   = WideChar;
  UnicodeString = WideString;
{$IFEND}

  TBinTextEncoding = (bteUnknown,bteBase2,bteBase8,bteBase10,bteBase16,
                      bteHexadecimal,bteBase32,bteBase32Hex,bteBase64,bteBase85);

  EBinTextEncError     = class(Exception);
  EUnknownEncoding     = class(EBinTextEncError);
  EUnsupportedEncoding = class(EBinTextEncError);
  EEncodingError       = class(EBinTextEncError);
  EDecodingError       = class(EBinTextEncError);
  EAllocationError     = class(EBinTextEncError);
  EInvalidCharacter    = class(EBinTextEncError);
  ETooMuchData         = class(EBinTextEncError);
  EHeaderWontFit       = class(EBinTextEncError);
  EEncodedTextTooShort = class(EBinTextEncError);


{==============================================================================}
{------------------------------------------------------------------------------}
{    Encoding alphabets and constatns                                          }
{------------------------------------------------------------------------------}
{==============================================================================}
const
  AnsiPaddingChar_Base8     = AnsiChar('=');
  AnsiPaddingChar_Base32    = AnsiChar('=');
  AnsiPaddingChar_Base32Hex = AnsiChar('=');
  AnsiPaddingChar_Base64    = AnsiChar('=');

  WidePaddingChar_Base8     = UnicodeChar('=');
  WidePaddingChar_Base32    = UnicodeChar('=');
  WidePaddingChar_Base32Hex = UnicodeChar('=');
  WidePaddingChar_Base64    = UnicodeChar('=');

  AnsiCompressionChar_Base85 = AnsiChar('_');
  WideCompressionChar_Base85 = UnicodeChar('_');

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
    ('0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
     'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
     'w','x','y','z','A','B','C','D','E','F','G','H','I','J','K','L',
     'M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','.','-',
     ':','+','=','^','!','/','*','?','&','<','>','(',')','[',']','{',
     '}','@','%','$','#');
  WideEncodingTable_Base85: Array[0..84] of UnicodeChar =
    ('0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
     'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
     'w','x','y','z','A','B','C','D','E','F','G','H','I','J','K','L',
     'M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','.','-',
     ':','+','=','^','!','/','*','?','&','<','>','(',')','[',']','{',
     '}','@','%','$','#');

  AnsiCompressionChar_Ascii85 = AnsiChar('z');
  WideCompressionChar_Ascii85 = UnicodeChar('z');

  AnsiEncodingTable_Ascii85: Array[0..84] of AnsiChar =
    ('!','"','#','$','%','&','''','(',')','*','+',',','-','.','/','0',
     '1','2','3','4','5','6','7','8','9',':',';','<','=','>','?','@',
     'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
     'Q','R','S','T','U','V','W','X','Y','Z','[','\',']','^','_','`',
     'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p',
     'q','r','s','t','u');
  WideEncodingTable_Ascii85: Array[0..84] of UnicodeChar =
    ('!','"','#','$','%','&','''','(',')','*','+',',','-','.','/','0',
     '1','2','3','4','5','6','7','8','9',':',';','<','=','>','?','@',
     'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
     'Q','R','S','T','U','V','W','X','Y','Z','[','\',']','^','_','`',
     'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p',
     'q','r','s','t','u');

{==============================================================================}
{------------------------------------------------------------------------------}
{    Universal functions                                                       }
{------------------------------------------------------------------------------}
{==============================================================================}

Function BuildHeader(Encoding: TBinTextEncoding; Reversed: Boolean): String;
Function AnsiBuildHeader(Encoding: TBinTextEncoding; Reversed: Boolean): AnsiString;
Function WideBuildHeader(Encoding: TBinTextEncoding; Reversed: Boolean): UnicodeString;

Function GetEncoding(const Str: String; out Reversed: Boolean): TBinTextEncoding;
Function AnsiGetEncoding(const Str: AnsiString; out Reversed: Boolean): TBinTextEncoding;
Function WideGetEncoding(const Str: UnicodeString; out Reversed: Boolean): TBinTextEncoding;

Function EncodedLength(Encoding: TBinTextEncoding; DataSize: TDataSize; Header: Boolean = False; Padding: Boolean = True): TStrSize;

Function DecodedLength(Encoding: TBinTextEncoding; const Str: String; Header: Boolean = True): TDataSize;
Function AnsiDecodedLength(Encoding: TBinTextEncoding; const Str: AnsiString; Header: Boolean = True): TDataSize;
Function WideDecodedLength(Encoding: TBinTextEncoding; const Str: UnicodeString; Header: Boolean = True): TDataSize;

Function Encode(Encoding: TBinTextEncoding; Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): String;
Function AnsiEncode(Encoding: TBinTextEncoding; Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): AnsiString;
Function WideEncode(Encoding: TBinTextEncoding; Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): UnicodeString;

Function Decode(const Str: String; out Size: TDataSize): Pointer; overload;
Function AnsiDecode(const Str: AnsiString; out Size: TDataSize): Pointer; overload;
Function WideDecode(const Str: UnicodeString; out Size: TDataSize): Pointer; overload;

Function Decode(const Str: String; out Size: TDataSize; out Encoding: TBinTextEncoding): Pointer; overload;
Function AnsiDecode(const Str: AnsiString; out Size: TDataSize; out Encoding: TBinTextEncoding): Pointer; overload;
Function WideDecode(const Str: UnicodeString; out Size: TDataSize; out Encoding: TBinTextEncoding): Pointer; overload;

Function Decode(const Str: String; out Size: TDataSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): Pointer; overload;
Function AnsiDecode(const Str: AnsiString; out Size: TDataSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): Pointer; overload;
Function WideDecode(const Str: UnicodeString; out Size: TDataSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): Pointer; overload;

Function Decode(const Str: String; Ptr: Pointer; Size: TDataSize): TDataSize; overload;
Function AnsiDecode(const Str: AnsiString; Ptr: Pointer; Size: TDataSize): TDataSize; overload;
Function WideDecode(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize): TDataSize; overload;

Function Decode(const Str: String; Ptr: Pointer; Size: TDataSize; out Encoding: TBinTextEncoding): TDataSize; overload;
Function AnsiDecode(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; out Encoding: TBinTextEncoding): TDataSize; overload;
Function WideDecode(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; out Encoding: TBinTextEncoding): TDataSize; overload;

Function Decode(const Str: String; Ptr: Pointer; Size: TDataSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): TDataSize; overload;
Function AnsiDecode(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): TDataSize; overload;
Function WideDecode(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): TDataSize; overload;

{==============================================================================}
{------------------------------------------------------------------------------}
{    Functions calculating length of encoded text from size of data that has   }
{    to be encoded                                                             }
{------------------------------------------------------------------------------}
{==============================================================================}

Function EncodedLength_Base2(DataSize: TDataSize; Header: Boolean = False): TStrSize;
Function EncodedLength_Base8(DataSize: TDataSize; Header: Boolean = False; Padding: Boolean = True): TStrSize;
Function EncodedLength_Base10(DataSize: TDataSize; Header: Boolean = False): TStrSize;
Function EncodedLength_Base16(DataSize: TDataSize; Header: Boolean = False): TStrSize;
Function EncodedLength_Hexadecimal(DataSize: TDataSize; Header: Boolean = False): TStrSize;
Function EncodedLength_Base32(DataSize: TDataSize; Header: Boolean = False; Padding: Boolean = True): TStrSize;
Function EncodedLength_Base32Hex(DataSize: TDataSize; Header: Boolean = False; Padding: Boolean = True): TStrSize;
Function EncodedLength_Base64(DataSize: TDataSize; Header: Boolean = False; Padding: Boolean = True): TStrSize;
Function EncodedLength_Base85(Data: Pointer; DataSize: TDataSize; Reversed: Boolean; Header: Boolean = False; Compression: Boolean = True; Trim: Boolean = True): TStrSize;

{==============================================================================}
{------------------------------------------------------------------------------}
{    Functions calculating size of encoded data from length of encoded text    }
{------------------------------------------------------------------------------}
{==============================================================================}

Function DecodedLength_Base2(const Str: String; Header: Boolean = False): TDataSize;
Function AnsiDecodedLength_Base2(const Str: AnsiString; Header: Boolean = False): TDataSize;
Function WideDecodedLength_Base2(const Str: UnicodeString; Header: Boolean = False): TDataSize;

Function DecodedLength_Base8(const Str: String; Header: Boolean = False): TDataSize; overload;
Function AnsiDecodedLength_Base8(const Str: AnsiString; Header: Boolean = False): TDataSize; overload;
Function WideDecodedLength_Base8(const Str: UnicodeString; Header: Boolean = False): TDataSize; overload;
Function DecodedLength_Base8(const Str: String; Header: Boolean; PaddingChar: Char): TDataSize; overload;
Function AnsiDecodedLength_Base8(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): TDataSize; overload;
Function WideDecodedLength_Base8(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): TDataSize; overload;

Function DecodedLength_Base10(const Str: String; Header: Boolean = False): TDataSize;
Function AnsiDecodedLength_Base10(const Str: AnsiString; Header: Boolean = False): TDataSize;
Function WideDecodedLength_Base10(const Str: UnicodeString; Header: Boolean = False): TDataSize;

Function DecodedLength_Base16(const Str: String; Header: Boolean = False): TDataSize;
Function AnsiDecodedLength_Base16(const Str: AnsiString; Header: Boolean = False): TDataSize;
Function WideDecodedLength_Base16(const Str: UnicodeString; Header: Boolean = False): TDataSize;

Function DecodedLength_Hexadecimal(const Str: String; Header: Boolean = False): TDataSize;
Function AnsiDecodedLength_Hexadecimal(const Str: AnsiString; Header: Boolean = False): TDataSize;
Function WideDecodedLength_Hexadecimal(const Str: UnicodeString; Header: Boolean = False): TDataSize;

Function DecodedLength_Base32(const Str: String; Header: Boolean = False): TDataSize; overload;
Function AnsiDecodedLength_Base32(const Str: AnsiString; Header: Boolean = False): TDataSize; overload;
Function WideDecodedLength_Base32(const Str: UnicodeString; Header: Boolean = False): TDataSize; overload;
Function DecodedLength_Base32(const Str: String; Header: Boolean; PaddingChar: Char): TDataSize; overload;
Function AnsiDecodedLength_Base32(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): TDataSize; overload;
Function WideDecodedLength_Base32(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): TDataSize; overload;

Function DecodedLength_Base32Hex(const Str: String; Header: Boolean = False): TDataSize; overload;
Function AnsiDecodedLength_Base32Hex(const Str: AnsiString; Header: Boolean = False): TDataSize; overload;
Function WideDecodedLength_Base32Hex(const Str: UnicodeString; Header: Boolean = False): TDataSize; overload;
Function DecodedLength_Base32Hex(const Str: String; Header: Boolean; PaddingChar: Char): TDataSize; overload;
Function AnsiDecodedLength_Base32Hex(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): TDataSize; overload;
Function WideDecodedLength_Base32Hex(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): TDataSize; overload;

Function DecodedLength_Base64(const Str: String; Header: Boolean = False): TDataSize; overload;
Function AnsiDecodedLength_Base64(const Str: AnsiString; Header: Boolean = False): TDataSize; overload;
Function WideDecodedLength_Base64(const Str: UnicodeString; Header: Boolean = False): TDataSize; overload;
Function DecodedLength_Base64(const Str: String; Header: Boolean; PaddingChar: Char): TDataSize; overload;
Function AnsiDecodedLength_Base64(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): TDataSize; overload;
Function WideDecodedLength_Base64(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): TDataSize; overload;

Function DecodedLength_Base85(const Str: String; Header: Boolean = False): TDataSize; overload;
Function AnsiDecodedLength_Base85(const Str: AnsiString; Header: Boolean = False): TDataSize; overload;
Function WideDecodedLength_Base85(const Str: UnicodeString; Header: Boolean = False): TDataSize; overload;
Function DecodedLength_Base85(const Str: String; Header: Boolean; CompressionChar: Char): TDataSize; overload;
Function AnsiDecodedLength_Base85(const Str: AnsiString; Header: Boolean; CompressionChar: AnsiChar): TDataSize; overload;
Function WideDecodedLength_Base85(const Str: UnicodeString; Header: Boolean; CompressionChar: UnicodeChar): TDataSize; overload;

{==============================================================================}
{------------------------------------------------------------------------------}
{    Encoding functions                                                        }
{------------------------------------------------------------------------------}
{==============================================================================}

Function Encode_Base2(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): String; overload;
Function AnsiEncode_Base2(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): AnsiString; overload;
Function WideEncode_Base2(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): UnicodeString; overload;

Function Encode_Base2(Data: Pointer; Size: TDataSize; Reversed: Boolean; const EncodingTable: Array of Char): String; overload;
Function AnsiEncode_Base2(Data: Pointer; Size: TDataSize; Reversed: Boolean; const EncodingTable: Array of AnsiChar): AnsiString; overload;
Function WideEncode_Base2(Data: Pointer; Size: TDataSize; Reversed: Boolean; const EncodingTable: Array of UnicodeChar): UnicodeString; overload;

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Encode_Base8(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): String; overload;
Function AnsiEncode_Base8(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): AnsiString; overload;
Function WideEncode_Base8(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): UnicodeString; overload;

Function Encode_Base8(Data: Pointer; Size: TDataSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of Char; PaddingChar: Char): String; overload;
Function AnsiEncode_Base8(Data: Pointer; Size: TDataSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of AnsiChar; PaddingChar: AnsiChar): AnsiString; overload;
Function WideEncode_Base8(Data: Pointer; Size: TDataSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): UnicodeString; overload;

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Encode_Base10(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): String; overload;
Function AnsiEncode_Base10(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): AnsiString; overload;
Function WideEncode_Base10(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): UnicodeString; overload;

Function Encode_Base10(Data: Pointer; Size: TDataSize; Reversed: Boolean; const EncodingTable: Array of Char): String; overload;
Function AnsiEncode_Base10(Data: Pointer; Size: TDataSize; Reversed: Boolean; const EncodingTable: Array of AnsiChar): AnsiString; overload;
Function WideEncode_Base10(Data: Pointer; Size: TDataSize; Reversed: Boolean; const EncodingTable: Array of UnicodeChar): UnicodeString; overload;

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Encode_Base16(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): String; overload;
Function AnsiEncode_Base16(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): AnsiString; overload;
Function WideEncode_Base16(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): UnicodeString; overload;

Function Encode_Base16(Data: Pointer; Size: TDataSize; Reversed: Boolean; const EncodingTable: Array of Char): String; overload;
Function AnsiEncode_Base16(Data: Pointer; Size: TDataSize; Reversed: Boolean; const EncodingTable: Array of AnsiChar): AnsiString; overload;
Function WideEncode_Base16(Data: Pointer; Size: TDataSize; Reversed: Boolean; const EncodingTable: Array of UnicodeChar): UnicodeString; overload;

Function Encode_Hexadecimal(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): String;
Function AnsiEncode_Hexadecimal(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): AnsiString;
Function WideEncode_Hexadecimal(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): UnicodeString;

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Encode_Base32(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): String; overload;
Function AnsiEncode_Base32(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): AnsiString; overload;
Function WideEncode_Base32(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): UnicodeString; overload;

Function Encode_Base32(Data: Pointer; Size: TDataSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of Char; PaddingChar: Char): String; overload;
Function AnsiEncode_Base32(Data: Pointer; Size: TDataSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of AnsiChar; PaddingChar: AnsiChar): AnsiString; overload;
Function WideEncode_Base32(Data: Pointer; Size: TDataSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): UnicodeString; overload;

Function Encode_Base32Hex(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): String; overload;
Function AnsiEncode_Base32Hex(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): AnsiString; overload;
Function WideEncode_Base32Hex(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): UnicodeString; overload;

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Encode_Base64(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): String; overload;
Function AnsiEncode_Base64(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): AnsiString; overload;
Function WideEncode_Base64(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): UnicodeString; overload;

Function Encode_Base64(Data: Pointer; Size: TDataSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of Char; PaddingChar: Char): String; overload;
Function AnsiEncode_Base64(Data: Pointer; Size: TDataSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of AnsiChar; PaddingChar: AnsiChar): AnsiString; overload;
Function WideEncode_Base64(Data: Pointer; Size: TDataSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): UnicodeString; overload;

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Encode_Base85(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Compression: Boolean = True; Trim: Boolean = True): String; overload;
Function AnsiEncode_Base85(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Compression: Boolean = True; Trim: Boolean = True): AnsiString; overload;
Function WideEncode_Base85(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Compression: Boolean = True; Trim: Boolean = True): UnicodeString; overload;

Function Encode_Base85(Data: Pointer; Size: TDataSize; Reversed: Boolean; Compression: Boolean; Trim: Boolean; const EncodingTable: Array of Char; CompressionChar: Char): String; overload;
Function AnsiEncode_Base85(Data: Pointer; Size: TDataSize; Reversed: Boolean; Compression: Boolean; Trim: Boolean; const EncodingTable: Array of AnsiChar; CompressionChar: AnsiChar): AnsiString; overload;
Function WideEncode_Base85(Data: Pointer; Size: TDataSize; Reversed: Boolean; Compression: Boolean; Trim: Boolean; const EncodingTable: Array of UnicodeChar; CompressionChar: UnicodeChar): UnicodeString; overload;

{==============================================================================}
{------------------------------------------------------------------------------}
{    Decoding functions                                                        }
{------------------------------------------------------------------------------}
{==============================================================================}

Function Decode_Base2(const Str: String; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;
Function AnsiDecode_Base2(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;
Function WideDecode_Base2(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;

Function Decode_Base2(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;
Function AnsiDecode_Base2(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;
Function WideDecode_Base2(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;

Function Decode_Base2(const Str: String; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char): Pointer; overload;
Function AnsiDecode_Base2(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Pointer; overload;
Function WideDecode_Base2(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar): Pointer; overload;

Function Decode_Base2(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char): TDataSize; overload;
Function AnsiDecode_Base2(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar): TDataSize; overload;
Function WideDecode_Base2(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar): TDataSize; overload;

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Decode_Base8(const Str: String; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;
Function AnsiDecode_Base8(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;
Function WideDecode_Base8(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;

Function Decode_Base8(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;
Function AnsiDecode_Base8(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;
Function WideDecode_Base8(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;

Function Decode_Base8(const Str: String; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char; PaddingChar: Char): Pointer; overload;
Function AnsiDecode_Base8(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar; PaddingChar: AnsiChar): Pointer; overload;
Function WideDecode_Base8(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): Pointer; overload;

Function Decode_Base8(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char; PaddingChar: Char): TDataSize; overload;
Function AnsiDecode_Base8(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar; PaddingChar: AnsiChar): TDataSize; overload;
Function WideDecode_Base8(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): TDataSize; overload;

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Decode_Base10(const Str: String; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;
Function AnsiDecode_Base10(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;
Function WideDecode_Base10(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;

Function Decode_Base10(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;
Function AnsiDecode_Base10(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;
Function WideDecode_Base10(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;

Function Decode_Base10(const Str: String; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char): Pointer; overload;
Function AnsiDecode_Base10(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Pointer; overload;
Function WideDecode_Base10(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar): Pointer; overload;

Function Decode_Base10(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char): TDataSize; overload;
Function AnsiDecode_Base10(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar): TDataSize; overload;
Function WideDecode_Base10(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar): TDataSize; overload;

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Decode_Base16(const Str: String; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;
Function AnsiDecode_Base16(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;
Function WideDecode_Base16(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;

Function Decode_Base16(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;
Function AnsiDecode_Base16(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;
Function WideDecode_Base16(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;

Function Decode_Base16(const Str: String; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char): Pointer; overload;
Function AnsiDecode_Base16(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Pointer; overload;
Function WideDecode_Base16(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar): Pointer; overload;

Function Decode_Base16(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char): TDataSize; overload;
Function AnsiDecode_Base16(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar): TDataSize; overload;
Function WideDecode_Base16(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar): TDataSize; overload;

Function Decode_Hexadecimal(const Str: String; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;
Function AnsiDecode_Hexadecimal(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;
Function WideDecode_Hexadecimal(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;

Function Decode_Hexadecimal(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;
Function AnsiDecode_Hexadecimal(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;
Function WideDecode_Hexadecimal(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Decode_Base32(const Str: String; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;
Function AnsiDecode_Base32(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;
Function WideDecode_Base32(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;

Function Decode_Base32(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;
Function AnsiDecode_Base32(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;
Function WideDecode_Base32(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;

Function Decode_Base32(const Str: String; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char; PaddingChar: Char): Pointer; overload;
Function AnsiDecode_Base32(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar; PaddingChar: AnsiChar): Pointer; overload;
Function WideDecode_Base32(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): Pointer; overload;

Function Decode_Base32(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char; PaddingChar: Char): TDataSize; overload;
Function AnsiDecode_Base32(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar; PaddingChar: AnsiChar): TDataSize; overload;
Function WideDecode_Base32(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): TDataSize; overload;

Function Decode_Base32Hex(const Str: String; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;
Function AnsiDecode_Base32Hex(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;
Function WideDecode_Base32Hex(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;

Function Decode_Base32Hex(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;
Function AnsiDecode_Base32Hex(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;
Function WideDecode_Base32Hex(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Decode_Base64(const Str: String; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;
Function AnsiDecode_Base64(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;
Function WideDecode_Base64(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;

Function Decode_Base64(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;
Function AnsiDecode_Base64(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;
Function WideDecode_Base64(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;

Function Decode_Base64(const Str: String; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char; PaddingChar: Char): Pointer; overload;
Function AnsiDecode_Base64(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar; PaddingChar: AnsiChar): Pointer; overload;
Function WideDecode_Base64(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): Pointer; overload;

Function Decode_Base64(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char; PaddingChar: Char): TDataSize; overload;
Function AnsiDecode_Base64(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar; PaddingChar: AnsiChar): TDataSize; overload;
Function WideDecode_Base64(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): TDataSize; overload;

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Decode_Base85(const Str: String; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;
Function AnsiDecode_Base85(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;
Function WideDecode_Base85(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean = False): Pointer; overload;

Function Decode_Base85(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;
Function AnsiDecode_Base85(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;
Function WideDecode_Base85(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; overload;

Function Decode_Base85(const Str: String; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char; CompressionChar: Char): Pointer; overload;
Function AnsiDecode_Base85(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar; CompressionChar: AnsiChar): Pointer; overload;
Function WideDecode_Base85(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar; CompressionChar: UnicodeChar): Pointer; overload;

Function Decode_Base85(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char; CompressionChar: Char): TDataSize; overload;
Function AnsiDecode_Base85(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar; CompressionChar: AnsiChar): TDataSize; overload;
Function WideDecode_Base85(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar; CompressionChar: UnicodeChar): TDataSize; overload;


implementation

uses
  Math;

const
  AnsiEncodingHexadecimal = AnsiChar('$');
  AnsiEncodingHeaderStart = AnsiChar('#');
  AnsiEncodingHeaderEnd   = AnsiChar(':');

  WideEncodingHexadecimal = UnicodeChar('$');
  WideEncodingHeaderStart = UnicodeChar('#');
  WideEncodingHeaderEnd   = UnicodeChar(':');

  HeaderLength = Length(AnsiEncodingHeaderStart + '00' + AnsiEncodingHeaderEnd);
  
  HexadecimalHeaderLength = Length(AnsiEncodingHexadecimal);

  ENCNUM_BASE2     = 2;
  ENCNUM_BASE8     = 8;
  ENCNUM_BASE10    = 10;
  ENCNUM_BASE16    = 16;
  ENCNUM_BASE32    = 32;
  ENCNUM_BASE32HEX = 33;
  ENCNUM_BASE64    = 64;
  ENCNUM_BASE85    = 85;  

  Coefficients_Base10: Array[1..3] of Word     = (100,10,1);
  Coefficients_Base85: Array[1..5] of LongWord = (52200625,614125,7225,85,1);

{==============================================================================}
{------------------------------------------------------------------------------}
{    Auxiliary functions                                                       }
{------------------------------------------------------------------------------}
{==============================================================================}

Function GetEncodingNumber(Encoding: TBinTextEncoding): Byte;
begin
case Encoding of
  bteBase2:       Result := ENCNUM_BASE2;
  bteBase8:       Result := ENCNUM_BASE8;
  bteBase10:      Result := ENCNUM_BASE10;
  bteBase16:      Result := ENCNUM_BASE16;
  bteHexadecimal: raise EUnsupportedEncoding.Create('GetEncodingNumber: Hexadecimal encoding is not supported by this function.');
  bteBase32:      Result := ENCNUM_BASE32;
  bteBase32Hex:   Result := ENCNUM_BASE32HEX;
  bteBase64:      Result := ENCNUM_BASE64;
  bteBase85:      Result := ENCNUM_BASE85;
else
  raise EUnknownEncoding.CreateFmt('GetEncodingNumber: Unknown encoding (%d).',[Integer(Encoding)]);
end;
end;

{------------------------------------------------------------------------------}

procedure ResolveDataPointer(var Ptr: Pointer; Reversed: Boolean; Size: TDataSize; EndOffset: LongWord = 1);
begin
If Reversed and Assigned(Ptr) then
  Ptr := {%H-}Pointer(PtrUInt(Ptr) + Size - EndOffset);
end;

{------------------------------------------------------------------------------}

procedure AdvanceDataPointer(var Ptr: Pointer; Reversed: Boolean; Step: Byte = 1);
begin
If Reversed then
  Ptr := {%H-}Pointer(PtrUInt(Ptr) - Step)
else
  Ptr := {%H-}Pointer(PtrUInt(Ptr) + Step);
end;

{------------------------------------------------------------------------------}

procedure DecodeCheckSize(Size, Required: TDataSize; Base: Integer; MaxError: LongWord = 0);
begin
If (Size + MaxError) < Required then
  raise EAllocationError.CreateFmt('DecodeCheckSize[base%d]: Output buffer too small (%d, required %d).',[Base,Size,Required]);
end;

{------------------------------------------------------------------------------}

Function AnsiTableIndex(const aChar: AnsiChar; const Table: Array of AnsiChar; Base: Integer): Byte;
begin
For Result := Low(Table) to High(Table) do
  If Table[Result] = aChar then Exit;
raise EInvalidCharacter.CreateFmt('AnsiTableIndex[base%d]: Invalid character "%s" (#%d).',[Base,aChar,Ord(aChar)]);
end;

{------------------------------------------------------------------------------}

Function WideTableIndex(const aChar: UnicodeChar; const Table: Array of UnicodeChar; Base: Integer): Byte;
begin
For Result := Low(Table) to High(Table) do
  If Table[Result] = aChar then Exit;
raise EInvalidCharacter.CreateFmt('WideTableIndex[base%d]: Invalid character "%s" (#%d).',[Base,aChar,Ord(aChar)]);
end;

{------------------------------------------------------------------------------}

Function AnsiCountPadding(Str: AnsiString; PaddingChar: AnsiChar): TStrSize;
var
  i:  TStrSize;
begin
Result := 0;
For i := Length(Str) downto 1 do
  If Str[i] = PaddingChar then Inc(Result)
    else Break;
end;

{------------------------------------------------------------------------------}

Function WideCountPadding(Str: UnicodeString; PaddingChar: UnicodeChar): TStrSize;
var
  i:  TStrSize;
begin
Result := 0;
For i := Length(Str) downto 1 do
  If Str[i] = PaddingChar then Inc(Result)
    else Break;
end;

{------------------------------------------------------------------------------}

Function AnsiCountChars(Str: AnsiString; Character: AnsiChar): TStrSize;
var
  i:  TStrSize;
begin
Result := 0;
For i := 1 to Length(Str) do
  If Str[i] = Character then Inc(Result);
end;

{------------------------------------------------------------------------------}

Function WideCountChars(Str: UnicodeString; Character: UnicodeChar): TStrSize;
var
  i:  TStrSize;
begin
Result := 0;
For i := 1 to Length(Str) do
  If Str[i] = Character then Inc(Result);
end;

{------------------------------------------------------------------------------}

{$IFDEF FPC}{$ASMMODE Intel}{$ENDIF}
procedure SwapByteOrder(var Value: LongWord); register; {$IFNDEF PurePascal}assembler;{$ENDIF}
{$IFDEF PurePascal}
begin
Value := LongWord((Value and $000000FF shl 24) or (Value and $0000FF00 shl 8) or
                  (Value and $00FF0000 shr 8) or (Value and $FF000000 shr 24));
end;
{$ELSE}
asm
  MOV     EDX, [Value]
  BSWAP   EDX
  MOV     [Value], EDX
end;
{$ENDIF}

{==============================================================================}
{------------------------------------------------------------------------------}
{    Universal functions                                                       }
{------------------------------------------------------------------------------}
{==============================================================================}

Function BuildHeader(Encoding: TBinTextEncoding; Reversed: Boolean): String;
begin
{$IFDEF Unicode}
Result := WideBuildHeader(Encoding,Reversed);
{$ELSE}
Result := AnsiBuildHeader(Encoding,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiBuildHeader(Encoding: TBinTextEncoding; Reversed: Boolean): AnsiString;
var
  EncodingNum:  Byte;
begin
If Encoding = bteHexadecimal then
  Result := AnsiEncodingHexadecimal
else
  begin
    EncodingNum := GetEncodingNumber(Encoding);
    If Reversed then EncodingNum := EncodingNum or $80
      else EncodingNum := EncodingNum and $7F;
    Result := AnsiEncodingHeaderStart +
              AnsiEncode_Hexadecimal(@EncodingNum,SizeOf(EncodingNum),False) +
              AnsiEncodingHeaderEnd;
  end;
end;

{------------------------------------------------------------------------------}

Function WideBuildHeader(Encoding: TBinTextEncoding; Reversed: Boolean): UnicodeString;
var
  EncodingNum:  Byte;
begin
If Encoding = bteHexadecimal then
  Result := WideEncodingHexadecimal
else
  begin
    EncodingNum := GetEncodingNumber(Encoding);
    If Reversed then EncodingNum := EncodingNum or $80
      else EncodingNum := EncodingNum and $7F;
    Result := WideEncodingHeaderStart +
              WideEncode_Hexadecimal(@EncodingNum,SizeOf(EncodingNum),False) +
              WideEncodingHeaderEnd;
  end;
end;

{------------------------------------------------------------------------------}

Function GetEncoding(const Str: String; out Reversed: Boolean): TBinTextEncoding;
begin
{$IFDEF Unicode}
Result := WideGetEncoding(Str,Reversed);
{$ELSE}
Result := AnsiGetEncoding(Str,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiGetEncoding(const Str: AnsiString; out Reversed: Boolean): TBinTextEncoding;
var
  EncByte:  Byte;
begin
If Length(Str) > 0 then
  begin
    case Str[1] of
{---  ----    ----    ----    ----    ----    ----    ----    ----    ----  ---}
      AnsiEncodingHexadecimal:
        begin
          Reversed := False;
          Result := bteHexadecimal;
        end;
{---  ----    ----    ----    ----    ----    ----    ----    ----    ----  ---}
      AnsiEncodingHeaderStart:
        begin
          If Length(Str) >= HeaderLength then
            begin
              If Str[HeaderLength] = AnsiEncodingHeaderEnd then
                begin
                  AnsiDecode_Hexadecimal(Copy(Str,1 + Length(AnsiEncodingHeaderStart),2),@EncByte,SizeOf(EncByte),False);
                  Reversed := (EncByte and $80) <> 0;
                  case (EncByte and $7F) of
                    ENCNUM_BASE2:     Result := bteBase2;
                    ENCNUM_BASE8:     Result := bteBase8;
                    ENCNUM_BASE10:    Result := bteBase10;
                    ENCNUM_BASE16:    Result := bteBase16;
                    ENCNUM_BASE32:    Result := bteBase32;
                    ENCNUM_BASE32HEX: Result := bteBase32Hex;
                    ENCNUM_BASE64:    Result := bteBase64;
                    ENCNUM_BASE85:    Result := bteBase85;
                  else
                    Result := bteUnknown;
                  end;
                end
              else Result := bteUnknown;
            end
          else Result := bteUnknown;
        end;
{---  ----    ----    ----    ----    ----    ----    ----    ----    ----  ---}
    else
      Result := bteUnknown;
    end;
  end
else Result := bteUnknown;
end;

{------------------------------------------------------------------------------}

Function WideGetEncoding(const Str: UnicodeString; out Reversed: Boolean): TBinTextEncoding;
var
  EncByte:  Byte;
begin
If Length(Str) > 0 then
  begin
    case Str[1] of
{---  ----    ----    ----    ----    ----    ----    ----    ----    ----  ---}
      WideEncodingHexadecimal:
        begin
          Reversed := False;
          Result := bteHexadecimal;
        end;
{---  ----    ----    ----    ----    ----    ----    ----    ----    ----  ---}
      WideEncodingHeaderStart:
        begin
          If Length(Str) >= HeaderLength then
            begin
              If Str[HeaderLength] = AnsiEncodingHeaderEnd then
                begin
                  WideDecode_Hexadecimal(Copy(Str,1 + Length(WideEncodingHeaderStart),2),@EncByte,SizeOf(EncByte),False);
                  Reversed := (EncByte and $80) <> 0;
                  case (EncByte and $7F) of
                    ENCNUM_BASE2:     Result := bteBase2;
                    ENCNUM_BASE8:     Result := bteBase8;
                    ENCNUM_BASE10:    Result := bteBase10;
                    ENCNUM_BASE16:    Result := bteBase16;
                    ENCNUM_BASE32:    Result := bteBase32;
                    ENCNUM_BASE32HEX: Result := bteBase32Hex;
                    ENCNUM_BASE64:    Result := bteBase64;
                    ENCNUM_BASE85:    Result := bteBase85;
                  else
                    Result := bteUnknown;
                  end;
                end
              else Result := bteUnknown;
            end
          else Result := bteUnknown;
        end;
{---  ----    ----    ----    ----    ----    ----    ----    ----    ----  ---}
    else
      Result := bteUnknown;
    end;
  end
else Result := bteUnknown;
end;

{==============================================================================}

Function EncodedLength(Encoding: TBinTextEncoding; DataSize: TDataSize; Header: Boolean = False; Padding: Boolean = True): TStrSize;
begin
case Encoding of
  bteBase2:       Result := EncodedLength_Base2(DataSize,Header);
  bteBase8:       Result := EncodedLength_Base8(DataSize,Header,Padding);
  bteBase10:      Result := EncodedLength_Base10(DataSize,Header);
  bteBase16:      Result := EncodedLength_Base16(DataSize,Header);
  bteHexadecimal: Result := EncodedLength_Hexadecimal(DataSize,Header);
  bteBase32:      Result := EncodedLength_Base32Hex(DataSize,Header,Padding);
  bteBase32Hex:   Result := EncodedLength_Base32(DataSize,Header,Padding);
  bteBase64:      Result := EncodedLength_Base64(DataSize,Header,Padding);
  bteBase85:      raise EUnsupportedEncoding.Create('EncodedLength: Base85 encoding is not supported by this function.');
else
  raise EUnknownEncoding.CreateFmt('EncodedLength: Unknown encoding (%d).',[Integer(Encoding)]);
end;
end;

{==============================================================================}

Function DecodedLength(Encoding: TBinTextEncoding; const Str: String; Header: Boolean = True): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength(Encoding,Str,Header);
{$ELSE}
Result := AnsiDecodedLength(Encoding,Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength(Encoding: TBinTextEncoding; const Str: AnsiString; Header: Boolean = True): TDataSize;
begin
case Encoding of
  bteBase2:       Result := AnsiDecodedLength_Base2(Str,Header);
  bteBase8:       Result := AnsiDecodedLength_Base8(Str,Header,AnsiPaddingChar_Base8);
  bteBase10:      Result := AnsiDecodedLength_Base10(Str,Header);
  bteBase16:      Result := AnsiDecodedLength_Base16(Str,Header);
  bteHexadecimal: Result := AnsiDecodedLength_Hexadecimal(Str,Header);
  bteBase32:      Result := AnsiDecodedLength_Base32(Str,Header,AnsiPaddingChar_Base32);
  bteBase32Hex:   Result := AnsiDecodedLength_Base32(Str,Header,AnsiPaddingChar_Base32Hex);
  bteBase64:      Result := AnsiDecodedLength_Base64(Str,Header,AnsiPaddingChar_Base64);
  bteBase85:      Result := AnsiDecodedLength_Base85(Str,Header,AnsiCompressionChar_Base85);
else
  raise EUnknownEncoding.CreateFmt('AnsiDecodedLength: Unknown encoding (%d).',[Integer(Encoding)]);
end;
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength(Encoding: TBinTextEncoding; const Str: UnicodeString; Header: Boolean = True): TDataSize;
begin
case Encoding of
  bteBase2:       Result := WideDecodedLength_Base2(Str,Header);
  bteBase8:       Result := WideDecodedLength_Base8(Str,Header,WidePaddingChar_Base8);
  bteBase10:      Result := WideDecodedLength_Base10(Str,Header);
  bteBase16:      Result := WideDecodedLength_Base16(Str,Header);
  bteHexadecimal: Result := WideDecodedLength_Hexadecimal(Str,Header);
  bteBase32:      Result := WideDecodedLength_Base32(Str,Header,WidePaddingChar_Base32);
  bteBase32Hex:   Result := WideDecodedLength_Base32(Str,Header,WidePaddingChar_Base32Hex);
  bteBase64:      Result := WideDecodedLength_Base64(Str,Header,WidePaddingChar_Base64);
  bteBase85:      Result := WideDecodedLength_Base85(Str,Header,WideCompressionChar_Base85);
else
  raise EUnknownEncoding.CreateFmt('WideDecodedLength: Unknown encoding (%d).',[Integer(Encoding)]);
end;
end;

{==============================================================================}

Function Encode(Encoding: TBinTextEncoding; Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): String;
begin
{$IFDEF Unicode}
Result := WideEncode(Encoding,Data,Size,Reversed,Padding);
{$ELSE}
Result := AnsiEncode(Encoding,Data,Size,Reversed,Padding);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode(Encoding: TBinTextEncoding; Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): AnsiString;
begin
case Encoding of
  bteBase2:       Result := AnsiBuildHeader(Encoding,Reversed) + AnsiEncode_Base2(Data,Size,Reversed);
  bteBase8:       Result := AnsiBuildHeader(Encoding,Reversed) + AnsiEncode_Base8(Data,Size,Reversed,Padding);
  bteBase10:      Result := AnsiBuildHeader(Encoding,Reversed) + AnsiEncode_Base10(Data,Size,Reversed);
  bteBase16:      Result := AnsiBuildHeader(Encoding,Reversed) + AnsiEncode_Base16(Data,Size,Reversed);
  bteHexadecimal: Result := AnsiBuildHeader(Encoding,Reversed) + AnsiEncode_Hexadecimal(Data,Size,False);
  bteBase32:      Result := AnsiBuildHeader(Encoding,Reversed) + AnsiEncode_Base32(Data,Size,Reversed,Padding);
  bteBase32Hex:   Result := AnsiBuildHeader(Encoding,Reversed) + AnsiEncode_Base32(Data,Size,Reversed,Padding);
  bteBase64:      Result := AnsiBuildHeader(Encoding,Reversed) + AnsiEncode_Base64(Data,Size,Reversed,Padding);
  bteBase85:      Result := AnsiBuildHeader(Encoding,Reversed) + AnsiEncode_Base85(Data,Size,Reversed,True,not Padding);
else
  raise EUnknownEncoding.CreateFmt('AnsiEncode: Unknown encoding (%d).',[Integer(Encoding)]);
end;
end;

{------------------------------------------------------------------------------}

Function WideEncode(Encoding: TBinTextEncoding; Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): UnicodeString;
begin
case Encoding of
  bteBase2:       Result := WideBuildHeader(Encoding,Reversed) + WideEncode_Base2(Data,Size,Reversed);
  bteBase8:       Result := WideBuildHeader(Encoding,Reversed) + WideEncode_Base8(Data,Size,Reversed,Padding);
  bteBase10:      Result := WideBuildHeader(Encoding,Reversed) + WideEncode_Base10(Data,Size,Reversed);
  bteBase16:      Result := WideBuildHeader(Encoding,Reversed) + WideEncode_Base16(Data,Size,Reversed);
  bteHexadecimal: Result := WideBuildHeader(Encoding,Reversed) + WideEncode_Hexadecimal(Data,Size,False);
  bteBase32:      Result := WideBuildHeader(Encoding,Reversed) + WideEncode_Base32(Data,Size,Reversed,Padding);
  bteBase32Hex:   Result := WideBuildHeader(Encoding,Reversed) + WideEncode_Base32(Data,Size,Reversed,Padding);
  bteBase64:      Result := WideBuildHeader(Encoding,Reversed) + WideEncode_Base64(Data,Size,Reversed,Padding);
  bteBase85:      Result := WideBuildHeader(Encoding,Reversed) + WideEncode_Base85(Data,Size,Reversed,True,not Padding);
else
  raise EUnknownEncoding.CreateFmt('WideEncode: Unknown encoding (%d).',[Integer(Encoding)]);
end;
end;

{==============================================================================}

Function Decode(const Str: String; out Size: TDataSize): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode(Str,Size);
{$ELSE}
Result := AnsiDecode(Str,Size);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode(const Str: AnsiString; out Size: TDataSize): Pointer;
var
  Encoding: TBinTextEncoding;
begin
Result := AnsiDecode(Str,Size,Encoding);
end;

{------------------------------------------------------------------------------}

Function WideDecode(const Str: UnicodeString; out Size: TDataSize): Pointer;
var
  Encoding: TBinTextEncoding;
begin
Result := WideDecode(Str,Size,Encoding);
end;

{------------------------------------------------------------------------------}

Function Decode(const Str: String; out Size: TDataSize; out Encoding: TBinTextEncoding): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode(Str,Size,Encoding);
{$ELSE}
Result := AnsiDecode(Str,Size,Encoding);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode(const Str: AnsiString; out Size: TDataSize; out Encoding: TBinTextEncoding): Pointer;
var
  Reversed: Boolean;
begin
Result := AnsiDecode(Str,Size,Encoding,Reversed);
end;

{------------------------------------------------------------------------------}

Function WideDecode(const Str: UnicodeString; out Size: TDataSize; out Encoding: TBinTextEncoding): Pointer;
var
  Reversed: Boolean;
begin
Result := WideDecode(Str,Size,Encoding,Reversed);
end;

{------------------------------------------------------------------------------}

Function Decode(const Str: String; out Size: TDataSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode(Str,Size,Encoding,Reversed);
{$ELSE}
Result := AnsiDecode(Str,Size,Encoding,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode(const Str: AnsiString; out Size: TDataSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): Pointer;
begin
Encoding := AnsiGetEncoding(Str,Reversed);
case Encoding of
  bteBase2:       Result := AnsiDecode_Base2(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Size,Reversed);
  bteBase8:       Result := AnsiDecode_Base8(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Size,Reversed);
  bteBase10:      Result := AnsiDecode_Base10(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Size,Reversed);
  bteBase16:      Result := AnsiDecode_Base16(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Size,Reversed);
  bteHexadecimal: Result := AnsiDecode_Hexadecimal(Copy(Str,HexadecimalHeaderLength + 1,Length(Str) - HexadecimalHeaderLength),Size,Reversed);
  bteBase32:      Result := AnsiDecode_Base32(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Size,Reversed);
  bteBase32Hex:   Result := AnsiDecode_Base32(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Size,Reversed);
  bteBase64:      Result := AnsiDecode_Base64(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Size,Reversed);
  bteBase85:      Result := AnsiDecode_Base85(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Size,Reversed);
else
  raise EUnknownEncoding.CreateFmt('AnsiDecode: Unknown encoding (%d).',[Integer(Encoding)]);
end;
end;

{------------------------------------------------------------------------------}

Function WideDecode(const Str: UnicodeString; out Size: TDataSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): Pointer;
begin
Encoding := WideGetEncoding(Str,Reversed);
case Encoding of
  bteBase2:       Result := WideDecode_Base2(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Size,Reversed);
  bteBase8:       Result := WideDecode_Base8(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Size,Reversed);
  bteBase10:      Result := WideDecode_Base10(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Size,Reversed);
  bteBase16:      Result := WideDecode_Base16(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Size,Reversed);
  bteHexadecimal: Result := WideDecode_Hexadecimal(Copy(Str,HexadecimalHeaderLength + 1,Length(Str) - HexadecimalHeaderLength),Size,Reversed);
  bteBase32:      Result := WideDecode_Base32(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Size,Reversed);
  bteBase32Hex:   Result := WideDecode_Base32(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Size,Reversed);
  bteBase64:      Result := WideDecode_Base64(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Size,Reversed);
  bteBase85:      Result := WideDecode_Base85(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Size,Reversed);
else
  raise EUnknownEncoding.CreateFmt('WideDecode: Unknown encoding (%d).',[Integer(Encoding)]);
end;
end;

{------------------------------------------------------------------------------}

Function Decode(const Str: String; Ptr: Pointer; Size: TDataSize): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecode(Str,Ptr,Size);
{$ELSE}
Result := AnsiDecode(Str,Ptr,Size);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode(const Str: AnsiString; Ptr: Pointer; Size: TDataSize): TDataSize;
var
  Encoding: TBinTextEncoding;
begin
Result := AnsiDecode(Str,Ptr,Size,Encoding);
end;

{------------------------------------------------------------------------------}

Function WideDecode(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize): TDataSize;
var
  Encoding: TBinTextEncoding;
begin
Result := WideDecode(Str,Ptr,Size,Encoding);
end;

{------------------------------------------------------------------------------}

Function Decode(const Str: String; Ptr: Pointer; Size: TDataSize; out Encoding: TBinTextEncoding): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecode(Str,Ptr,Size,Encoding);
{$ELSE}
Result := AnsiDecode(Str,Ptr,Size,Encoding);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; out Encoding: TBinTextEncoding): TDataSize;
var
  Reversed: Boolean;
begin
Result := AnsiDecode(Str,Ptr,Size,Encoding,Reversed);
end;

{------------------------------------------------------------------------------}

Function WideDecode(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; out Encoding: TBinTextEncoding): TDataSize;
var
  Reversed: Boolean;
begin
Result := WideDecode(Str,Ptr,Size,Encoding,Reversed);
end;

{------------------------------------------------------------------------------}

Function Decode(const Str: String; Ptr: Pointer; Size: TDataSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecode(Str,Ptr,Size,Encoding,Reversed);
{$ELSE}
Result := AnsiDecode(Str,Ptr,Size,Encoding,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): TDataSize;
begin
Encoding := AnsiGetEncoding(Str,Reversed);
case Encoding of
  bteBase2:       Result := AnsiDecode_Base2(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Ptr,Size,Reversed);
  bteBase8:       Result := AnsiDecode_Base8(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Ptr,Size,Reversed);
  bteBase10:      Result := AnsiDecode_Base10(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Ptr,Size,Reversed);
  bteBase16:      Result := AnsiDecode_Base16(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Ptr,Size,Reversed);
  bteHexadecimal: Result := AnsiDecode_Base16(Copy(Str,HexadecimalHeaderLength + 1,Length(Str) - HexadecimalHeaderLength),Ptr,Size,Reversed);
  bteBase32:      Result := AnsiDecode_Base32(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Ptr,Size,Reversed);
  bteBase32Hex:   Result := AnsiDecode_Base32(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Ptr,Size,Reversed);
  bteBase64:      Result := AnsiDecode_Base64(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Ptr,Size,Reversed);
  bteBase85:      Result := AnsiDecode_Base85(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Ptr,Size,Reversed);
else
  raise EUnknownEncoding.CreateFmt('AnsiDecode: Unknown encoding (%d).',[Integer(Encoding)]);
end;
end;

{------------------------------------------------------------------------------}

Function WideDecode(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): TDataSize;
begin
Encoding := WideGetEncoding(Str,Reversed);
case Encoding of
  bteBase2:       Result := WideDecode_Base2(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Ptr,Size,Reversed);
  bteBase8:       Result := WideDecode_Base8(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Ptr,Size,Reversed);
  bteBase10:      Result := WideDecode_Base10(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Ptr,Size,Reversed);
  bteBase16:      Result := WideDecode_Base16(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Ptr,Size,Reversed);
  bteHexadecimal: Result := WideDecode_Base16(Copy(Str,HexadecimalHeaderLength + 1,Length(Str) - HexadecimalHeaderLength),Ptr,Size,Reversed);
  bteBase32:      Result := WideDecode_Base32(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Ptr,Size,Reversed);
  bteBase32Hex:   Result := WideDecode_Base32(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Ptr,Size,Reversed);
  bteBase64:      Result := WideDecode_Base64(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Ptr,Size,Reversed);
  bteBase85:      Result := WideDecode_Base85(Copy(Str,HeaderLength + 1,Length(Str) - HeaderLength),Ptr,Size,Reversed);
else
  raise EUnknownEncoding.CreateFmt('WideDecode: Unknown encoding (%d).',[Integer(Encoding)]);
end;
end;

{==============================================================================}
{------------------------------------------------------------------------------}
{    Functions calculating length of encoded text from size of data that has   }
{    to be encoded                                                             }
{------------------------------------------------------------------------------}
{==============================================================================}

Function EncodedLength_Base2(DataSize: TDataSize; Header: Boolean = False): TStrSize;
begin
If DataSize <= (High(TStrSize) div 8) then
  begin
    Result := DataSize * 8;
    If Header then
      begin
        If (TDataSize(Result) + TDataSize(HeaderLength)) <= TDataSize(High(TStrSize)) then Result := Result + HeaderLength
          else raise EHeaderWontFit.Create('EncodedLength_Base2: Header won''t fit into resulting string.');
      end;
  end
else raise ETooMuchData.CreateFmt('EncodedLength_Base2: Too much data (%d).',[DataSize]);
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Base8(DataSize: TDataSize; Header: Boolean = False; Padding: Boolean = True): TStrSize;
var
  Temp: TDataSize;
begin
If Padding then Temp := Ceil(DataSize / 3) * 8
  else Temp := Ceil(DataSize * (8/3));
If Temp <= TDataSize(High(TStrSize)) then
  begin
    Result := Temp;
    If Header then
      begin
        If (TDataSize(Result) + TDataSize(HeaderLength)) <= TDataSize(High(TStrSize)) then Result := Result + HeaderLength
          else raise EHeaderWontFit.Create('EncodedLength_Base8: Header won''t fit into resulting string.');
      end;
  end
else raise ETooMuchData.CreateFmt('EncodedLength_Base8: Too much data (%d).',[DataSize]);
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Base10(DataSize: TDataSize; Header: Boolean = False): TStrSize;
begin
If DataSize <= (High(TStrSize) div 3) then
  begin
    Result := DataSize * 3;
    If Header then
      begin
        If (TDataSize(Result) + TDataSize(HeaderLength)) <= TDataSize(High(TStrSize)) then Result := Result + HeaderLength
          else raise EHeaderWontFit.Create('EncodedLength_Base10: Header won''t fit into resulting string.');
      end;
  end
else raise ETooMuchData.CreateFmt('EncodedLength_Base10: Too much data (%d).',[DataSize]);
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Base16(DataSize: TDataSize; Header: Boolean = False): TStrSize;
begin
If DataSize <= (High(TStrSize) div 2) then
  begin
    Result := DataSize * 2;
    If Header then
      begin
        If (TDataSize(Result) + TDataSize(HeaderLength)) <= TDataSize(High(TStrSize)) then Result := Result + HeaderLength
          else raise EHeaderWontFit.Create('EncodedLength_Base16: Header won''t fit into resulting string.');
      end;
  end
else raise ETooMuchData.CreateFmt('EncodedLength_Base16: Too much data (%d).',[DataSize]);
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Hexadecimal(DataSize: TDataSize; Header: Boolean = False): TStrSize;
begin
If DataSize <= (High(TStrSize) div 2) then
  begin
    Result := DataSize * 2;
    If Header then
      begin
        If (TDataSize(Result) + TDataSize(HexadecimalHeaderLength)) <= TDataSize(High(TStrSize)) then Result := Result + HexadecimalHeaderLength
          else raise EHeaderWontFit.Create('EncodedLength_Hexadecimal: Header won''t fit into resulting string.');
      end;
  end
else raise ETooMuchData.CreateFmt('EncodedLength_Hexadecimal: Too much data (%d).',[DataSize]);
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Base32(DataSize: TDataSize; Header: Boolean = False; Padding: Boolean = True): TStrSize;
var
  Temp: TDataSize;
begin
If Padding then Temp := Ceil(DataSize / 5) * 8
  else Temp := Ceil(DataSize * (8/5));
If Temp <= TDataSize(High(TStrSize)) then
  begin
    Result := Temp;
    If Header then
      begin
        If (TDataSize(Result) + TDataSize(HeaderLength)) <= TDataSize(High(TStrSize)) then Result := Result + HeaderLength
          else raise EHeaderWontFit.Create('EncodedLength_Base32: Header won''t fit into resulting string.');
      end;
  end
else raise ETooMuchData.CreateFmt('EncodedLength_Base32: Too much data (%d).',[DataSize]);
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Base32Hex(DataSize: TDataSize; Header: Boolean = False; Padding: Boolean = True): TStrSize;
begin
Result := EncodedLength_Base32(DataSize,Header,Padding);
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Base64(DataSize: TDataSize; Header: Boolean = False; Padding: Boolean = True): TStrSize;
var
  Temp: TDataSize;
begin
If Padding then Temp := Ceil(DataSize / 3) * 4
  else Temp := Ceil(DataSize * (4/3));
If Temp <= TDataSize(High(TStrSize)) then
  begin
    Result := Temp;
    If Header then
      begin
        If (TDataSize(Result) + TDataSize(HeaderLength)) <= TDataSize(High(TStrSize)) then Result := Result + HeaderLength
          else raise EHeaderWontFit.Create('EncodedLength_Base64: Header won''t fit into resulting string.');
      end;
  end
else raise ETooMuchData.CreateFmt('EncodedLength_Base64: Too much data (%d).',[DataSize]);
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Base85(Data: Pointer; DataSize: TDataSize; Reversed: Boolean; Header: Boolean = False; Compression: Boolean = True; Trim: Boolean = True): TStrSize;
var
  Temp: TDataSize;

  Function CountCompressible(Ptr: PLongWord): TDataSize;
  var
    ii: TDataSize;
  begin
    Result := 0;
    ResolveDataPointer(Pointer(Ptr),Reversed,DataSize,4);
    For ii := 1 to (DataSize div 4) do
      begin
        If PLongWord(Ptr)^ = 0 then Inc(Result);
        AdvanceDataPointer(Pointer(Ptr),Reversed,4)
      end;
  end;

begin
If Trim then Temp := TDataSize(Ceil(DataSize / 4)) + DataSize
  else Temp := TDataSize(Ceil(DataSize / 4)) * 5;
If Compression then Temp := Temp - (CountCompressible(Data) * Int64(4));
If Temp <= TDataSize(High(TStrSize)) then
  begin
    Result := Temp;
    If Header then
      begin
        If (TDataSize(Result) + TDataSize(HeaderLength)) <= TDataSize(High(TStrSize)) then Result := Result + HeaderLength
          else raise EHeaderWontFit.Create('EncodedLength_Base85: Header won''t fit into resulting string.');
      end;
  end
else raise ETooMuchData.CreateFmt('EncodedLength_Base85: Too much data (%d).',[DataSize]);
end;

{==============================================================================}
{------------------------------------------------------------------------------}
{    Functions calculating size of encoded data from length of encoded text    }
{------------------------------------------------------------------------------}
{==============================================================================}

Function DecodedLength_Base2(const Str: String; Header: Boolean = False): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base2(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base2(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base2(const Str: AnsiString; Header: Boolean = False): TDataSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := (Length(Str) - HeaderLength) div 8
    else
      raise EEncodedTextTooShort.Create('AnsiDecodedLength_Base2: Encoded text is too short to contain valid header.');
  end
else Result := Length(Str) div 8;
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base2(const Str: UnicodeString; Header: Boolean = False): TDataSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := (Length(Str) - HeaderLength) div 8
    else
      raise EEncodedTextTooShort.Create('WideDecodedLength_Base2: Encoded text is too short to contain valid header.');
  end
else Result := Length(Str) div 8;
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base8(const Str: String; Header: Boolean = False): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base8(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base8(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base8(const Str: AnsiString; Header: Boolean = False): TDataSize;
begin
Result := AnsiDecodedLength_Base8(Str,Header,AnsiPaddingChar_Base8);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base8(const Str: UnicodeString; Header: Boolean = False): TDataSize;
begin
Result := WideDecodedLength_Base8(Str,Header,WidePaddingChar_Base8);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base8(const Str: String; Header: Boolean; PaddingChar: Char): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base8(Str,Header,PaddingChar);
{$ELSE}
Result := AnsiDecodedLength_Base8(Str,Header,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base8(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): TDataSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := Floor((((Length(Str) - HeaderLength) - AnsiCountPadding(Str,PaddingChar)) / 8) * 3)
    else
      raise EEncodedTextTooShort.Create('AnsiDecodedLength_Base8: Encoded text is too short to contain valid header.');
  end
else Result := Floor(((Length(Str) - AnsiCountPadding(Str,PaddingChar)) / 8) * 3);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base8(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): TDataSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := Floor((((Length(Str) - HeaderLength) - WideCountPadding(Str,PaddingChar)) / 8) * 3)
    else
      raise EEncodedTextTooShort.Create('WideDecodedLength_Base8: Encoded text is too short to contain valid header.');
  end
else Result := Floor(((Length(Str) - WideCountPadding(Str,PaddingChar)) / 8) * 3);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base10(const Str: String; Header: Boolean = False): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base10(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base10(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base10(const Str: AnsiString; Header: Boolean = False): TDataSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := (Length(Str) - HeaderLength) div 3
    else
      raise EEncodedTextTooShort.Create('AnsiDecodedLength_Base10: Encoded text is too short to contain valid header.');
  end
else Result := Length(Str) div 3;
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base10(const Str: UnicodeString; Header: Boolean = False): TDataSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := (Length(Str) - HeaderLength) div 3
    else
      raise EEncodedTextTooShort.Create('WideDecodedLength_Base10: Encoded text is too short to contain valid header.');
  end
else Result := Length(Str) div 3;
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base16(const Str: String; Header: Boolean = False): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base16(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base16(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base16(const Str: AnsiString; Header: Boolean = False): TDataSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := (Length(Str) - HeaderLength) div 2
    else
      raise EEncodedTextTooShort.Create('AnsiDecodedLength_Base16: Encoded text is too short to contain valid header.');
  end
else Result := Length(Str) div 2;
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base16(const Str: UnicodeString; Header: Boolean = False): TDataSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := (Length(Str) - HeaderLength) div 2
    else
      raise EEncodedTextTooShort.Create('WideDecodedLength_Base16: Encoded text is too short to contain valid header.');
  end
else Result := Length(Str) div 2;
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Hexadecimal(const Str: String; Header: Boolean = False): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Hexadecimal(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Hexadecimal(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Hexadecimal(const Str: AnsiString; Header: Boolean = False): TDataSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := (Length(Str) - HexadecimalHeaderLength) div 2
    else
      raise EEncodedTextTooShort.Create('AnsiDecodedLength_Hexadecimal: Encoded text is too short to contain valid header.');
  end
else Result := Length(Str) div 2;
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Hexadecimal(const Str: UnicodeString; Header: Boolean = False): TDataSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := (Length(Str) - HexadecimalHeaderLength) div 2
    else
      raise EEncodedTextTooShort.Create('WideDecodedLength_Hexadecimal: Encoded text is too short to contain valid header.');
  end
else Result := Length(Str) div 2;
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base32(const Str: String; Header: Boolean = False): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base32(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base32(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base32(const Str: AnsiString; Header: Boolean = False): TDataSize;
begin
Result := AnsiDecodedLength_Base32(Str,Header,AnsiPaddingChar_Base32);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base32(const Str: UnicodeString; Header: Boolean = False): TDataSize;
begin
Result := WideDecodedLength_Base32(Str,Header,WidePaddingChar_Base32);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base32(const Str: String; Header: Boolean; PaddingChar: Char): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base32(Str,Header,PaddingChar);
{$ELSE}
Result := AnsiDecodedLength_Base32(Str,Header,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base32(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): TDataSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := Floor((((Length(Str) - HeaderLength) - AnsiCountPadding(Str,PaddingChar)) / 8) * 5)
    else
      raise EEncodedTextTooShort.Create('AnsiDecodedLength_Base32: Encoded text is too short to contain valid header.');
  end
else Result := Floor(((Length(Str) - AnsiCountPadding(Str,PaddingChar)) / 8) * 5);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base32(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): TDataSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := Floor((((Length(Str) - HeaderLength) - WideCountPadding(Str,PaddingChar)) / 8) * 5)
    else
      raise EEncodedTextTooShort.Create('WideDecodedLength_Base32: Encoded text is too short to contain valid header.');
  end
else Result := Floor(((Length(Str) - WideCountPadding(Str,PaddingChar)) / 8) * 5);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base32Hex(const Str: String; Header: Boolean = False): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base32Hex(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base32Hex(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base32Hex(const Str: AnsiString; Header: Boolean = False): TDataSize;
begin
Result := AnsiDecodedLength_Base32Hex(Str,Header,AnsiPaddingChar_Base32Hex);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base32Hex(const Str: UnicodeString; Header: Boolean = False): TDataSize;
begin
Result := WideDecodedLength_Base32Hex(Str,Header,WidePaddingChar_Base32Hex);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base32Hex(const Str: String; Header: Boolean; PaddingChar: Char): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base32Hex(Str,Header,PaddingChar);
{$ELSE}
Result := AnsiDecodedLength_Base32Hex(Str,Header,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base32Hex(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): TDataSize;
begin
Result := AnsiDecodedLength_Base32(Str,Header,PaddingChar);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base32Hex(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): TDataSize;
begin
Result := WideDecodedLength_Base32(Str,Header,PaddingChar);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base64(const Str: String; Header: Boolean = False): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base64(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base64(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base64(const Str: AnsiString; Header: Boolean = False): TDataSize;
begin
Result := AnsiDecodedLength_Base64(Str,Header,AnsiPaddingChar_Base64);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base64(const Str: UnicodeString; Header: Boolean = False): TDataSize;
begin
Result := WideDecodedLength_Base64(Str,Header,WidePaddingChar_Base64);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base64(const Str: String; Header: Boolean; PaddingChar: Char): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base64(Str,Header,PaddingChar);
{$ELSE}
Result := AnsiDecodedLength_Base64(Str,Header,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base64(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): TDataSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := Floor((((Length(Str) - HeaderLength) - AnsiCountPadding(Str,PaddingChar)) / 4) * 3)
    else
      raise EEncodedTextTooShort.Create('AnsiDecodedLength_Base64: Encoded text is too short to contain valid header.');
  end
else Result := Floor(((Length(Str) - AnsiCountPadding(Str,PaddingChar)) / 4) * 3);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base64(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): TDataSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := Floor((((Length(Str) - HeaderLength) - WideCountPadding(Str,PaddingChar)) / 4) * 3)
    else
      raise EEncodedTextTooShort.Create('WideDecodedLength_Base64: Encoded text is too short to contain valid header.');
  end
else Result := Floor(((Length(Str) - WideCountPadding(Str,PaddingChar)) / 4) * 3);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base85(const Str: String; Header: Boolean = False): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base85(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base85(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base85(const Str: AnsiString; Header: Boolean = False): TDataSize;
begin
Result := AnsiDecodedLength_Base85(Str,Header,AnsiCompressionChar_Base85);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base85(const Str: UnicodeString; Header: Boolean = False): TDataSize;
begin
Result := WideDecodedLength_Base85(Str,Header,WideCompressionChar_Base85);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base85(const Str: String; Header: Boolean; CompressionChar: Char): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base85(Str,Header,CompressionChar);
{$ELSE}
Result := AnsiDecodedLength_Base85(Str,Header,CompressionChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base85(const Str: AnsiString; Header: Boolean; CompressionChar: AnsiChar): TDataSize;
begin
Result := Length(Str) + (AnsiCountChars(Str,CompressionChar) * 4);
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := (Result - TDataSize(HeaderLength)) - TDataSize(Ceil((Result - TDataSize(HeaderLength)) / 5))
    else
      raise EEncodedTextTooShort.Create('AnsiDecodedLength_Base85: Encoded text is too short to contain valid header.');
  end
else Result := Result - TDataSize(Ceil(Result / 5));
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base85(const Str: UnicodeString; Header: Boolean; CompressionChar: UnicodeChar): TDataSize;
begin
Result := Length(Str) + (WideCountChars(Str,CompressionChar) * 4);
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := (Result - TDataSize(HeaderLength)) - TDataSize(Ceil((Result - TDataSize(HeaderLength)) / 5))
    else
      raise EEncodedTextTooShort.Create('WideDecodedLength_Base85: Encoded text is too short to contain valid header.');
  end
else Result := Result - TDataSize(Ceil(Result / 5));
end;

{==============================================================================}
{------------------------------------------------------------------------------}
{    Encoding functions                                                        }
{------------------------------------------------------------------------------}
{==============================================================================}

Function Encode_Base2(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base2(Data,Size,Reversed);
{$ELSE}
Result := AnsiEncode_Base2(Data,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base2(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): AnsiString;
begin
Result := AnsiEncode_Base2(Data,Size,Reversed,AnsiEncodingTable_Base2);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base2(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): UnicodeString;
begin
Result := WideEncode_Base2(Data,Size,Reversed,WideEncodingTable_Base2);
end;

{------------------------------------------------------------------------------}

Function Encode_Base2(Data: Pointer; Size: TDataSize; Reversed: Boolean; const EncodingTable: Array of Char): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base2(Data,Size,Reversed,EncodingTable);
{$ELSE}
Result := AnsiEncode_Base2(Data,Size,Reversed,EncodingTable);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base2(Data: Pointer; Size: TDataSize; Reversed: Boolean; const EncodingTable: Array of AnsiChar): AnsiString;
var
  Buffer: Byte;
  i,j:    TDataSize;
begin
ResolveDataPointer(Data,Reversed,Size);
SetLength(Result,EncodedLength_Base2(Size));
If Size > 0 then
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

Function WideEncode_Base2(Data: Pointer; Size: TDataSize; Reversed: Boolean; const EncodingTable: Array of UnicodeChar): UnicodeString;
var
  Buffer: Byte;
  i,j:    TDataSize;
begin
ResolveDataPointer(Data,Reversed,Size);
SetLength(Result,EncodedLength_Base2(Size));
If Size > 0 then
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

Function Encode_Base8(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base8(Data,Size,Reversed,Padding);
{$ELSE}
Result := AnsiEncode_Base8(Data,Size,Reversed,Padding);
{$ENDIF}
end;
 
{------------------------------------------------------------------------------}

Function AnsiEncode_Base8(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): AnsiString;
begin
Result := AnsiEncode_Base8(Data,Size,Reversed,Padding,AnsiEncodingTable_Base8,AnsiPaddingChar_Base8);
end;
 
{------------------------------------------------------------------------------}

Function WideEncode_Base8(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): UnicodeString;
begin
Result := WideEncode_Base8(Data,Size,Reversed,Padding,WideEncodingTable_Base8,WidePaddingChar_Base8);
end;

{------------------------------------------------------------------------------}

Function Encode_Base8(Data: Pointer; Size: TDataSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of Char; PaddingChar: Char): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base8(Data,Size,Reversed,Padding,EncodingTable,PaddingChar);
{$ELSE}
Result := AnsiEncode_Base8(Data,Size,Reversed,Padding,EncodingTable,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base8(Data: Pointer; Size: TDataSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of AnsiChar; PaddingChar: AnsiChar): AnsiString;
var
  Buffer:         Byte;
  i:              TDataSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  ResultPosition: TStrSize;
  j:              TStrSize;
begin
ResolveDataPointer(Data,Reversed,Size);
SetLength(Result,EncodedLength_Base8(Size,False,Padding));
Remainder := 0;
RemainderBits := 0;
ResultPosition := 1;
For i := 1 to Size do
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
      raise EEncodingError.CreateFmt('AnsiEncode_Base8: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    AdvanceDataPointer(Data,Reversed);
  end;
case RemainderBits of
  0:  ;
  1:  Result[ResultPosition] := EncodingTable[Remainder shl 2];
  2:  Result[ResultPosition] := EncodingTable[Remainder shl 1];
else
  raise EEncodingError.CreateFmt('AnsiEncode_Base8: Invalid RemainderBits value (%d).',[RemainderBits]);
end;
Inc(ResultPosition);
If Padding then
  For j := ResultPosition to Length(Result) do Result[j] := PaddingChar;
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base8(Data: Pointer; Size: TDataSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): UnicodeString;
var
  Buffer:         Byte;
  i:              TDataSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  ResultPosition: TStrSize;
  j:              TStrSize;
begin
ResolveDataPointer(Data,Reversed,Size);
SetLength(Result,EncodedLength_Base8(Size,False,Padding));
Remainder := 0;
RemainderBits := 0;
ResultPosition := 1;
For i := 1 to Size do
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
      raise EEncodingError.CreateFmt('WideEncode_Base8: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    AdvanceDataPointer(Data,Reversed);
  end;
case RemainderBits of
  0:  ;
  1:  Result[ResultPosition] := EncodingTable[Remainder shl 2];
  2:  Result[ResultPosition] := EncodingTable[Remainder shl 1];
else
  raise EEncodingError.CreateFmt('WideEncode_Base8: Invalid RemainderBits value (%d).',[RemainderBits]);
end;
Inc(ResultPosition);
If Padding then
  For j := ResultPosition to Length(Result) do Result[j] := PaddingChar;
end;

{==============================================================================}

Function Encode_Base10(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base10(Data,Size,Reversed);
{$ELSE}
Result := AnsiEncode_Base10(Data,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base10(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): AnsiString;
begin
Result := AnsiEncode_Base10(Data,Size,Reversed,AnsiEncodingTable_Base10);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base10(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): UnicodeString;
begin
Result := WideEncode_Base10(Data,Size,Reversed,WideEncodingTable_Base10);
end;

{------------------------------------------------------------------------------}

Function Encode_Base10(Data: Pointer; Size: TDataSize; Reversed: Boolean; const EncodingTable: Array of Char): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base10(Data,Size,Reversed,EncodingTable);
{$ELSE}
Result := AnsiEncode_Base10(Data,Size,Reversed,EncodingTable);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base10(Data: Pointer; Size: TDataSize; Reversed: Boolean; const EncodingTable: Array of AnsiChar): AnsiString;
var
  Buffer: Byte;
  i,j:    TDataSize;
begin
ResolveDataPointer(Data,Reversed,Size);
SetLength(Result,EncodedLength_Base10(Size));
If Size > 0 then
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

Function WideEncode_Base10(Data: Pointer; Size: TDataSize; Reversed: Boolean; const EncodingTable: Array of UnicodeChar): UnicodeString;
var
  Buffer: Byte;
  i,j:    TDataSize;
begin
ResolveDataPointer(Data,Reversed,Size);
SetLength(Result,EncodedLength_Base10(Size));
If Size > 0 then
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

Function Encode_Base16(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base16(Data,Size,Reversed);
{$ELSE}
Result := AnsiEncode_Base16(Data,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base16(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): AnsiString;
begin
Result := AnsiEncode_Base16(Data,Size,Reversed,AnsiEncodingTable_Base16);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base16(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): UnicodeString;
begin
Result := WideEncode_Base16(Data,Size,Reversed,WideEncodingTable_Base16);
end;

{------------------------------------------------------------------------------}

Function Encode_Base16(Data: Pointer; Size: TDataSize; Reversed: Boolean; const EncodingTable: Array of Char): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base16(Data,Size,Reversed,EncodingTable);
{$ELSE}
Result := AnsiEncode_Base16(Data,Size,Reversed,EncodingTable);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base16(Data: Pointer; Size: TDataSize; Reversed: Boolean; const EncodingTable: Array of AnsiChar): AnsiString;
var
  i:  TDataSize;
begin
ResolveDataPointer(Data,Reversed,Size);
SetLength(Result,EncodedLength_Base16(Size));
If Size > 0 then
  For i := 0 to Pred(Size) do
    begin
      Result[(i * 2) + 1] := EncodingTable[PByte(Data)^ shr 4];
      Result[(i * 2) + 2] := EncodingTable[PByte(Data)^ and $0F];
      AdvanceDataPointer(Data,Reversed);
    end;
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base16(Data: Pointer; Size: TDataSize; Reversed: Boolean; const EncodingTable: Array of UnicodeChar): UnicodeString;
var
  i:  TDataSize;
begin
ResolveDataPointer(Data,Reversed,Size);
SetLength(Result,EncodedLength_Base16(Size));
If Size > 0 then
  For i := 0 to Pred(Size) do
    begin
      Result[(i * 2) + 1] := EncodingTable[PByte(Data)^ shr 4];
      Result[(i * 2) + 2] := EncodingTable[PByte(Data)^ and $0F];
      AdvanceDataPointer(Data,Reversed);
    end;
end;

{------------------------------------------------------------------------------}

Function Encode_Hexadecimal(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Hexadecimal(Data,Size,Reversed);
{$ELSE}
Result := AnsiEncode_Hexadecimal(Data,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Hexadecimal(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): AnsiString;
begin
Result := AnsiEncode_Base16(Data,Size,Reversed,AnsiEncodingTable_Hexadecimal);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Hexadecimal(Data: Pointer; Size: TDataSize; Reversed: Boolean = False): UnicodeString;
begin
Result := WideEncode_Base16(Data,Size,Reversed,WideEncodingTable_Hexadecimal);
end;

{==============================================================================}

Function Encode_Base32(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base32(Data,Size,Reversed,Padding);
{$ELSE}
Result := AnsiEncode_Base32(Data,Size,Reversed,Padding);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base32(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): AnsiString;
begin
Result := AnsiEncode_Base32(Data,Size,Reversed,Padding,AnsiEncodingTable_Base32,AnsiPaddingChar_Base32);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base32(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): UnicodeString;
begin
Result := WideEncode_Base32(Data,Size,Reversed,Padding,WideEncodingTable_Base32,WidePaddingChar_Base32);
end;

{------------------------------------------------------------------------------}

Function Encode_Base32(Data: Pointer; Size: TDataSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of Char; PaddingChar: Char): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base32(Data,Size,Reversed,Padding,EncodingTable,PaddingChar);
{$ELSE}
Result := AnsiEncode_Base32(Data,Size,Reversed,Padding,EncodingTable,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base32(Data: Pointer; Size: TDataSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of AnsiChar; PaddingChar: AnsiChar): AnsiString;
var
  Buffer:         Byte;
  i:              TDataSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  ResultPosition: TStrSize;
  j:              TStrSize;
begin
ResolveDataPointer(Data,Reversed,Size);
SetLength(Result,EncodedLength_Base32(Size,False,Padding));
Remainder := 0;
RemainderBits := 0;
ResultPosition := 1;
For i := 1 to Size do
  begin
    Buffer := PByte(Data)^;
    case RemainderBits of
      0:  begin
            Result[ResultPosition] := EncodingTable[(Buffer and $F8) shr 3];
            Inc(ResultPosition,1);
            Remainder := Buffer and $07;
            RemainderBits := 3;
          end;
      1:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 4) or ((Buffer and $F0) shr 4)];
            Inc(ResultPosition,1);
            Remainder := Buffer and $0F;
            RemainderBits := 4;
          end;
      2:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 3) or ((Buffer and $E0) shr 5)];
            Result[ResultPosition + 1] := EncodingTable[Buffer and $1F];
            Inc(ResultPosition,2);
            Remainder := 0;
            RemainderBits := 0;
          end;
      3:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 2) or ((Buffer and $C0) shr 6)];
            Result[ResultPosition + 1] := EncodingTable[(Buffer and $3E) shr 1];
            Inc(ResultPosition,2);
            Remainder := Buffer and $01;
            RemainderBits := 1;
          end;
      4:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 1) or ((Buffer and $80) shr 7)];
            Result[ResultPosition + 1] := EncodingTable[(Buffer and $7C) shr 2];
            Inc(ResultPosition,2);
            Remainder := Buffer and $03;
            RemainderBits := 2;
          end;
    else
      raise EEncodingError.CreateFmt('AnsiEncode_Base32: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    AdvanceDataPointer(Data,Reversed);
  end;
case RemainderBits of
  0:  ;
  1:  Result[ResultPosition] := EncodingTable[Remainder shl 4];
  2:  Result[ResultPosition] := EncodingTable[Remainder shl 3];
  3:  Result[ResultPosition] := EncodingTable[Remainder shl 2];
  4:  Result[ResultPosition] := EncodingTable[Remainder shl 1];
else
  raise EEncodingError.CreateFmt('AnsiEncode_Base32: Invalid RemainderBits value (%d).',[RemainderBits]);
end;
Inc(ResultPosition);
If Padding then
  For j := ResultPosition to Length(Result) do Result[j] := PaddingChar;
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base32(Data: Pointer; Size: TDataSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): UnicodeString;
var
  Buffer:         Byte;
  i:              TDataSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  ResultPosition: TStrSize;
  j:              TStrSize;
begin
ResolveDataPointer(Data,Reversed,Size);
SetLength(Result,EncodedLength_Base32(Size,False,Padding));
Remainder := 0;
RemainderBits := 0;
ResultPosition := 1;
For i := 1 to Size do
  begin
    Buffer := PByte(Data)^;
    case RemainderBits of
      0:  begin
            Result[ResultPosition] := EncodingTable[(Buffer and $F8) shr 3];
            Inc(ResultPosition,1);
            Remainder := Buffer and $07;
            RemainderBits := 3;
          end;
      1:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 4) or ((Buffer and $F0) shr 4)];
            Inc(ResultPosition,1);
            Remainder := Buffer and $0F;
            RemainderBits := 4;
          end;
      2:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 3) or ((Buffer and $E0) shr 5)];
            Result[ResultPosition + 1] := EncodingTable[Buffer and $1F];
            Inc(ResultPosition,2);
            Remainder := 0;
            RemainderBits := 0;
          end;
      3:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 2) or ((Buffer and $C0) shr 6)];
            Result[ResultPosition + 1] := EncodingTable[(Buffer and $3E) shr 1];
            Inc(ResultPosition,2);
            Remainder := Buffer and $01;
            RemainderBits := 1;
          end;
      4:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 1) or ((Buffer and $80) shr 7)];
            Result[ResultPosition + 1] := EncodingTable[(Buffer and $7C) shr 2];
            Inc(ResultPosition,2);
            Remainder := Buffer and $03;
            RemainderBits := 2;
          end;
    else
      raise EEncodingError.CreateFmt('WideEncode_Base32: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    AdvanceDataPointer(Data,Reversed);
  end;
case RemainderBits of
  0:  ;
  1:  Result[ResultPosition] := EncodingTable[Remainder shl 4];
  2:  Result[ResultPosition] := EncodingTable[Remainder shl 3];
  3:  Result[ResultPosition] := EncodingTable[Remainder shl 2];
  4:  Result[ResultPosition] := EncodingTable[Remainder shl 1];
else
  raise EEncodingError.CreateFmt('WideEncode_Base32: Invalid RemainderBits value (%d).',[RemainderBits]);
end;
Inc(ResultPosition);
If Padding then
  For j := ResultPosition to Length(Result) do Result[j] := PaddingChar;
end;

{------------------------------------------------------------------------------}

Function Encode_Base32Hex(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base32Hex(Data,Size,Reversed,Padding);
{$ELSE}
Result := AnsiEncode_Base32Hex(Data,Size,Reversed,Padding);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base32Hex(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): AnsiString;
begin
Result := AnsiEncode_Base32(Data,Size,Reversed,Padding,AnsiEncodingTable_Base32Hex,AnsiPaddingChar_Base32Hex);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base32Hex(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): UnicodeString;
begin
Result := WideEncode_Base32(Data,Size,Reversed,Padding,WideEncodingTable_Base32Hex,WidePaddingChar_Base32Hex);
end;

{==============================================================================}

Function Encode_Base64(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base64(Data,Size,Reversed,Padding);
{$ELSE}
Result := AnsiEncode_Base64(Data,Size,Reversed,Padding);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base64(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): AnsiString;
begin
Result := AnsiEncode_Base64(Data,Size,Reversed,Padding,AnsiEncodingTable_Base64,AnsiPaddingChar_Base64);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base64(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Padding: Boolean = True): UnicodeString;
begin
Result := WideEncode_Base64(Data,Size,Reversed,Padding,WideEncodingTable_Base64,WidePaddingChar_Base64);
end;

{------------------------------------------------------------------------------}

Function Encode_Base64(Data: Pointer; Size: TDataSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of Char; PaddingChar: Char): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base64(Data,Size,Reversed,Padding,EncodingTable,PaddingChar);
{$ELSE}
Result := AnsiEncode_Base64(Data,Size,Reversed,Padding,EncodingTable,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base64(Data: Pointer; Size: TDataSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of AnsiChar; PaddingChar: AnsiChar): AnsiString;
var
  Buffer:         Byte;
  i:              TDataSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  ResultPosition: TStrSize;
  j:              TStrSize;
begin
ResolveDataPointer(Data,Reversed,Size);
SetLength(Result,EncodedLength_Base64(Size,False,Padding));
Remainder := 0;
RemainderBits := 0;
ResultPosition := 1;
For i := 1 to Size do
  begin
    Buffer := PByte(Data)^;
    case RemainderBits of
      0:  begin
            Result[ResultPosition] := EncodingTable[(Buffer and $FC) shr 2];
            Inc(ResultPosition,1);
            Remainder := Buffer and $03;
            RemainderBits := 2;
          end;
      2:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 4) or ((Buffer and $F0) shr 4)];
            Inc(ResultPosition,1);
            Remainder := Buffer and $0F;
            RemainderBits := 4;
          end;
      4:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 2) or ((Buffer and $C0) shr 6)];
            Result[ResultPosition + 1] := EncodingTable[Buffer and $3F];
            Inc(ResultPosition,2);
            Remainder := Buffer and $01;
            RemainderBits := 0;
          end;
    else
      raise EEncodingError.CreateFmt('AnsiEncode_Base64: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    AdvanceDataPointer(Data,Reversed);
  end;
case RemainderBits of
  0:  ;
  2:  Result[ResultPosition] := EncodingTable[Remainder shl 4];
  4:  Result[ResultPosition] := EncodingTable[Remainder shl 2];
else
  raise EEncodingError.CreateFmt('AnsiEncode_Base64: Invalid RemainderBits value (%d).',[RemainderBits]);
end;
Inc(ResultPosition);
If Padding then
  For j := ResultPosition to Length(Result) do Result[j] := PaddingChar;
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base64(Data: Pointer; Size: TDataSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): UnicodeString;
var
  Buffer:         Byte;
  i:              TDataSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  ResultPosition: TStrSize;
  j:              TStrSize;
begin
ResolveDataPointer(Data,Reversed,Size);
SetLength(Result,EncodedLength_Base64(Size,False,Padding));
Remainder := 0;
RemainderBits := 0;
ResultPosition := 1;
For i := 1 to Size do
  begin
    Buffer := PByte(Data)^;
    case RemainderBits of
      0:  begin
            Result[ResultPosition] := EncodingTable[(Buffer and $FC) shr 2];
            Inc(ResultPosition,1);
            Remainder := Buffer and $03;
            RemainderBits := 2;
          end;
      2:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 4) or ((Buffer and $F0) shr 4)];
            Inc(ResultPosition,1);
            Remainder := Buffer and $0F;
            RemainderBits := 4;
          end;
      4:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 2) or ((Buffer and $C0) shr 6)];
            Result[ResultPosition + 1] := EncodingTable[Buffer and $3F];
            Inc(ResultPosition,2);
            Remainder := Buffer and $01;
            RemainderBits := 0;
          end;
    else
      raise EEncodingError.CreateFmt('WideEncode_Base64: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    AdvanceDataPointer(Data,Reversed);
  end;
case RemainderBits of
  0:  ;
  2:  Result[ResultPosition] := EncodingTable[Remainder shl 4];
  4:  Result[ResultPosition] := EncodingTable[Remainder shl 2];
else
  raise EEncodingError.CreateFmt('WideEncode_Base64: Invalid RemainderBits value (%d).',[RemainderBits]);
end;
Inc(ResultPosition);
If Padding then
  For j := ResultPosition to Length(Result) do Result[j] := PaddingChar;
end;

{==============================================================================}

Function Encode_Base85(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Compression: Boolean = True; Trim: Boolean = True): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base85(Data,Size,Reversed,Compression,Trim);
{$ELSE}
Result := AnsiEncode_Base85(Data,Size,Reversed,Compression,Trim);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base85(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Compression: Boolean = True; Trim: Boolean = True): AnsiString;
begin
Result := AnsiEncode_Base85(Data,Size,Reversed,Compression,Trim,AnsiEncodingTable_Base85,AnsiCompressionChar_Base85);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base85(Data: Pointer; Size: TDataSize; Reversed: Boolean = False; Compression: Boolean = True; Trim: Boolean = True): UnicodeString;
begin
Result := WideEncode_Base85(Data,Size,Reversed,Compression,Trim,WideEncodingTable_Base85,WideCompressionChar_Base85);
end;

{------------------------------------------------------------------------------}

Function Encode_Base85(Data: Pointer; Size: TDataSize; Reversed: Boolean; Compression: Boolean; Trim: Boolean; const EncodingTable: Array of Char; CompressionChar: Char): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base85(Data,Size,Reversed,Compression,Trim,EncodingTable,CompressionChar);
{$ELSE}
Result := AnsiEncode_Base85(Data,Size,Reversed,Compression,Trim,EncodingTable,CompressionChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base85(Data: Pointer; Size: TDataSize; Reversed: Boolean; Compression: Boolean; Trim: Boolean; const EncodingTable: Array of AnsiChar; CompressionChar: AnsiChar): AnsiString;
var
  Buffer:         LongWord;
  i:              TDataSize;
  j:              TStrSize;
  ResultPosition: TStrSize;
begin
SetLength(Result,EncodedLength_Base85(Data,Size,Reversed,False,Compression,Trim));
ResolveDataPointer(Data,Reversed,Size,4);
ResultPosition := 1;
For i := 1 to Ceil(Size / 4) do
  begin
    If (i * 4) > Size then
      begin
        Buffer := 0;
        If Reversed then
          Move({%H-}Pointer(PtrUInt(Data) - PtrUInt(Size and 3) + 4)^,{%H-}Pointer(PtrUInt(@Buffer) - PtrUInt(Size and 3) + 4)^,Size and 3)
        else
          Move(Data^,Buffer,Size and 3);
      end
    else Buffer := PLongWord(Data)^;
    If not Reversed then SwapByteOrder(Buffer);
    If (Buffer = 0) and Compression and ((i * 4) <= Size) then
      begin
        Result[ResultPosition] := CompressionChar;
        Inc(ResultPosition);
      end
    else
      begin
        For j := 1 to Min(5,Length(Result) - ResultPosition + 1) do
          begin
            Result[ResultPosition + j - 1] := EncodingTable[Buffer div Coefficients_Base85[j]];
            Buffer := Buffer mod Coefficients_Base85[j];            
          end;
        Inc(ResultPosition,5);
      end;
    AdvanceDataPointer(Data,Reversed,4);
  end;
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base85(Data: Pointer; Size: TDataSize; Reversed: Boolean; Compression: Boolean; Trim: Boolean; const EncodingTable: Array of UnicodeChar; CompressionChar: UnicodeChar): UnicodeString;
var
  Buffer:         LongWord;
  i:              TDataSize;
  j:              TStrSize;
  ResultPosition: TStrSize;
begin
SetLength(Result,EncodedLength_Base85(Data,Size,Reversed,False,Compression,Trim));
ResolveDataPointer(Data,Reversed,Size,4);
ResultPosition := 1;
For i := 1 to Ceil(Size / 4) do
  begin
    If (i * 4) > Size then
      begin
        Buffer := 0;
        If Reversed then
          Move({%H-}Pointer(PtrUInt(Data) - PtrUInt(Size and 3) + 4)^,{%H-}Pointer(PtrUInt(@Buffer) - PtrUInt(Size and 3) + 4)^,Size and 3)
        else
          Move(Data^,Buffer,Size and 3);
      end
    else Buffer := PLongWord(Data)^;
    If not Reversed then SwapByteOrder(Buffer);
    If (Buffer = 0) and Compression and ((i * 4) <= Size) then
      begin
        Result[ResultPosition] := CompressionChar;
        Inc(ResultPosition);
      end
    else
      begin
        For j := 1 to Min(5,Length(Result) - ResultPosition + 1) do
          begin
            Result[ResultPosition + j - 1] := EncodingTable[Buffer div Coefficients_Base85[j]];
            Buffer := Buffer mod Coefficients_Base85[j];            
          end;
        Inc(ResultPosition,5);
      end;
    AdvanceDataPointer(Data,Reversed,4);
  end;
end;

{==============================================================================}
{------------------------------------------------------------------------------}
{    Decoding functions                                                        }
{------------------------------------------------------------------------------}
{==============================================================================}

Function Decode_Base2(const Str: String; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base2(Str,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base2(Str,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base2(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base2(Str,Size,Reversed,AnsiEncodingTable_Base2);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base2(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
Result := WideDecode_Base2(Str,Size,Reversed,WideEncodingTable_Base2);
end;

{------------------------------------------------------------------------------}

Function Decode_Base2(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base2(Str,Ptr,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base2(Str,Ptr,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base2(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
Result := AnsiDecode_Base2(Str,Ptr,Size,Reversed,AnsiEncodingTable_Base2);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base2(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
Result := WideDecode_Base2(Str,Ptr,Size,Reversed,WideEncodingTable_Base2);
end;

{------------------------------------------------------------------------------}

Function Decode_Base2(const Str: String; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base2(Str,Size,Reversed,DecodingTable);
{$ELSE}
Result := AnsiDecode_Base2(Str,Size,Reversed,DecodingTable);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base2(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Pointer;
var
  ResultSize: TDataSize;
begin
Size := AnsiDecodedLength_Base2(Str);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := AnsiDecode_Base2(Str,Result,Size,Reversed,DecodingTable);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('AnsiDecode_Base2: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Result := nil;
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base2(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar): Pointer;
var
  ResultSize: TDataSize;
begin
Size := WideDecodedLength_Base2(Str);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := WideDecode_Base2(Str,Result,Size,Reversed,DecodingTable);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('WideDecode_Base2: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Result := nil;
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function Decode_Base2(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base2(Str,Ptr,Size,Reversed,DecodingTable);
{$ELSE}
Result := AnsiDecode_Base2(Str,Ptr,Size,Reversed,DecodingTable);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base2(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar): TDataSize;
var
  Buffer: Byte;
  i,j:    TDataSize;
begin
Result := AnsiDecodedLength_Base2(Str);
DecodeCheckSize(Size,Result,2);
ResolveDataPointer(Ptr,Reversed,Size);
If Result > 0 then
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

Function WideDecode_Base2(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar): TDataSize;
var
  Buffer: Byte;
  i,j:    TDataSize;
begin
Result := WideDecodedLength_Base2(Str);
DecodeCheckSize(Size,Result,2);
ResolveDataPointer(Ptr,Reversed,Size);
If Result > 0 then
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

Function Decode_Base8(const Str: String; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base8(Str,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base8(Str,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base8(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base8(Str,Size,Reversed,AnsiEncodingTable_Base8,AnsiPaddingChar_Base8);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base8(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean = False): Pointer; 
begin
Result := WideDecode_Base8(Str,Size,Reversed,WideEncodingTable_Base8,WidePaddingChar_Base8);
end;

{------------------------------------------------------------------------------}

Function Decode_Base8(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; 
begin
{$IFDEF Unicode}
Result := WideDecode_Base8(Str,Ptr,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base8(Str,Ptr,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base8(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; 
begin
Result := AnsiDecode_Base8(Str,Ptr,Size,Reversed,AnsiEncodingTable_Base8,AnsiPaddingChar_Base8);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base8(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize; 
begin
Result := WideDecode_Base8(Str,Ptr,Size,Reversed,WideEncodingTable_Base8,WidePaddingChar_Base8);
end;

{------------------------------------------------------------------------------}

Function Decode_Base8(const Str: String; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char; PaddingChar: Char): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base8(Str,Size,Reversed,DecodingTable,PaddingChar);
{$ELSE}
Result := AnsiDecode_Base8(Str,Size,Reversed,DecodingTable,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base8(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar; PaddingChar: AnsiChar): Pointer;
var
  ResultSize: TDataSize;
begin
Size := AnsiDecodedLength_Base8(Str,False,PaddingChar);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := AnsiDecode_Base8(Str,Result,Size,Reversed,DecodingTable,PaddingChar);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('AnsiDecode_Base8: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Result := nil;
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base8(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): Pointer;
var
  ResultSize: TDataSize;
begin
Size := WideDecodedLength_Base8(Str,False,PaddingChar);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := WideDecode_Base8(Str,Result,Size,Reversed,DecodingTable,PaddingChar);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('WideDecode_Base8: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Result := nil;
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function Decode_Base8(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char; PaddingChar: Char): TDataSize; 
begin
{$IFDEF Unicode}
Result := WideDecode_Base8(Str,Ptr,Size,Reversed,DecodingTable,PaddingChar);
{$ELSE}
Result := AnsiDecode_Base8(Str,Ptr,Size,Reversed,DecodingTable,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base8(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar; PaddingChar: AnsiChar): TDataSize; 
var
  Buffer:         Byte;
  i:              TDataSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  StrPosition:    TStrSize;
begin
Result := AnsiDecodedLength_Base8(Str,False,PaddingChar);
DecodeCheckSize(Size,Result,8);
ResolveDataPointer(Ptr,Reversed,Size);
Remainder := 0;
RemainderBits := 0;
StrPosition := 1;
For i := 1 to Result do
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
      raise EDecodingError.CreateFmt('AnsiDecode_Base8: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    PByte(Ptr)^ := Buffer;
    AdvanceDataPointer(Ptr,Reversed);
  end;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base8(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): TDataSize; 
var
  Buffer:         Byte;
  i:              TDataSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  StrPosition:    TStrSize;
begin
Result := WideDecodedLength_Base8(Str,False,PaddingChar);
DecodeCheckSize(Size,Result,8);
ResolveDataPointer(Ptr,Reversed,Size);
Remainder := 0;
RemainderBits := 0;
StrPosition := 1;
For i := 1 to Result do
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
      raise EDecodingError.CreateFmt('WideDecode_Base8: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    PByte(Ptr)^ := Buffer;
    AdvanceDataPointer(Ptr,Reversed);
  end;
end;

{==============================================================================}

Function Decode_Base10(const Str: String; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base10(Str,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base10(Str,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base10(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base10(Str,Size,Reversed,AnsiEncodingTable_Base10);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base10(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
Result := WideDecode_Base10(Str,Size,Reversed,WideEncodingTable_Base10);
end;

{------------------------------------------------------------------------------}

Function Decode_Base10(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base10(Str,Ptr,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base10(Str,Ptr,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base10(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
Result := AnsiDecode_Base10(Str,Ptr,Size,Reversed,AnsiEncodingTable_Base10);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base10(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
Result := WideDecode_Base10(Str,Ptr,Size,Reversed,WideEncodingTable_Base10);
end;

{------------------------------------------------------------------------------}

Function Decode_Base10(const Str: String; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base10(Str,Size,Reversed,DecodingTable);
{$ELSE}
Result := AnsiDecode_Base10(Str,Size,Reversed,DecodingTable);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base10(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Pointer;
var
  ResultSize: TDataSize;
begin
Size := AnsiDecodedLength_Base10(Str);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := AnsiDecode_Base10(Str,Result,Size,Reversed,DecodingTable);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('AnsiDecode_Base10: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Result := nil;
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base10(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar): Pointer;
var
  ResultSize: TDataSize;
begin
Size := WideDecodedLength_Base10(Str);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := WideDecode_Base10(Str,Result,Size,Reversed,DecodingTable);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('WideDecode_Base10: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Result := nil;
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function Decode_Base10(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base10(Str,Ptr,Size,Reversed,DecodingTable);
{$ELSE}
Result := AnsiDecode_Base10(Str,Ptr,Size,Reversed,DecodingTable);
{$ENDIF}
end;


{------------------------------------------------------------------------------}

Function AnsiDecode_Base10(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar): TDataSize;
var
  i:  TDataSize;
begin
Result := AnsiDecodedLength_Base10(Str);
DecodeCheckSize(Size,Result,10);
ResolveDataPointer(Ptr,Reversed,Size);
If Result > 0 then
  For i := 0 to Pred(Result) do
    begin
      PByte(Ptr)^ := AnsiTableIndex(Str[(i * 3) + 1],DecodingTable,10) * Coefficients_Base10[1] +
                     AnsiTableIndex(Str[(i * 3) + 2],DecodingTable,10) * Coefficients_Base10[2] +
                     AnsiTableIndex(Str[(i * 3) + 3],DecodingTable,10) * Coefficients_Base10[3];
      AdvanceDataPointer(Ptr,Reversed)
    end;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base10(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar): TDataSize;
var
  i:  TDataSize;
begin
Result := WideDecodedLength_Base10(Str);
DecodeCheckSize(Size,Result,10);
ResolveDataPointer(Ptr,Reversed,Size);
If Result > 0 then
  For i := 0 to Pred(Result) do
    begin
      PByte(Ptr)^ := WideTableIndex(Str[(i * 3) + 1],DecodingTable,10) * Coefficients_Base10[1] +
                     WideTableIndex(Str[(i * 3) + 2],DecodingTable,10) * Coefficients_Base10[2] +
                     WideTableIndex(Str[(i * 3) + 3],DecodingTable,10) * Coefficients_Base10[3];
      AdvanceDataPointer(Ptr,Reversed)
    end;
end;

{==============================================================================}

Function Decode_Base16(const Str: String; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base16(Str,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base16(Str,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base16(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base16(Str,Size,Reversed,AnsiEncodingTable_Base16);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base16(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
Result := WideDecode_Base16(Str,Size,Reversed,WideEncodingTable_Base16);
end;

{------------------------------------------------------------------------------}

Function Decode_Base16(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base16(Str,Ptr,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base16(Str,Ptr,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base16(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
Result := AnsiDecode_Base16(Str,Ptr,Size,Reversed,AnsiEncodingTable_Base16);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base16(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
Result := WideDecode_Base16(Str,Ptr,Size,Reversed,WideEncodingTable_Base16);
end;

{------------------------------------------------------------------------------}

Function Decode_Base16(const Str: String; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base16(Str,Size,Reversed,DecodingTable);
{$ELSE}
Result := AnsiDecode_Base16(Str,Size,Reversed,DecodingTable);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base16(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar): Pointer;
var
  ResultSize: TDataSize;
begin
Size := AnsiDecodedLength_Base16(Str);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := AnsiDecode_Base16(Str,Result,Size,Reversed,DecodingTable);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('AnsiDecode_Base16: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Result := nil;
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base16(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar): Pointer;
var
  ResultSize: TDataSize;
begin
Size := WideDecodedLength_Base16(Str);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := WideDecode_Base16(Str,Result,Size,Reversed,DecodingTable);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('WideDecode_Base16: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Result := nil;
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function Decode_Base16(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base16(Str,Ptr,Size,Reversed,DecodingTable);
{$ELSE}
Result := AnsiDecode_Base16(Str,Ptr,Size,Reversed,DecodingTable);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base16(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar): TDataSize;
var
  i:  TDataSize;
begin
Result := AnsiDecodedLength_Base16(Str);
DecodeCheckSize(Size,Result,16);
ResolveDataPointer(Ptr,Reversed,Size);
If Result > 0 then
  For i := 0 to Pred(Result) do
    begin
      PByte(Ptr)^ := (AnsiTableIndex(Str[(i * 2) + 1],DecodingTable,16) shl 4) or
                     (AnsiTableIndex(Str[(i * 2) + 2],DecodingTable,16) and $0F);
      AdvanceDataPointer(Ptr,Reversed);
    end;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base16(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar): TDataSize;
var
  i:  TDataSize;
begin
Result := WideDecodedLength_Base16(Str);
DecodeCheckSize(Size,Result,16);
ResolveDataPointer(Ptr,Reversed,Size);
If Result > 0 then
  For i := 0 to Pred(Result) do
    begin
      PByte(Ptr)^ := (WideTableIndex(Str[(i * 2) + 1],DecodingTable,16) shl 4) or
                     (WideTableIndex(Str[(i * 2) + 2],DecodingTable,16) and $0F);
      AdvanceDataPointer(Ptr,Reversed);
    end;
end;

{------------------------------------------------------------------------------}

Function Decode_Hexadecimal(const Str: String; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Hexadecimal(Str,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Hexadecimal(Str,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Hexadecimal(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean = False): Pointer;
var
  ResultSize: TDataSize;
begin
Size := AnsiDecodedLength_Hexadecimal(Str);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := AnsiDecode_Hexadecimal(Str,Result,Size,Reversed);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('AnsiDecode_Hexadecimal: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Result := nil;
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Hexadecimal(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean = False): Pointer;
var
  ResultSize: TDataSize;
begin
Size := WideDecodedLength_Hexadecimal(Str);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := WideDecode_Hexadecimal(Str,Result,Size,Reversed);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('WideDecode_Hexadecimal: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Result := nil;
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function Decode_Hexadecimal(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Hexadecimal(Str,Ptr,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Hexadecimal(Str,Ptr,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Hexadecimal(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
Result := AnsiDecode_Base16(Str,Ptr,Size,Reversed,AnsiEncodingTable_Hexadecimal);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Hexadecimal(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
Result := WideDecode_Base16(Str,Ptr,Size,Reversed,WideEncodingTable_Hexadecimal);
end;

{==============================================================================}

Function Decode_Base32(const Str: String; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base32(Str,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base32(Str,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base32(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base32(Str,Size,Reversed,AnsiEncodingTable_Base32,AnsiPaddingChar_Base32);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base32(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
Result := WideDecode_Base32(Str,Size,Reversed,WideEncodingTable_Base32,WidePaddingChar_Base32);
end;

{------------------------------------------------------------------------------}

Function Decode_Base32(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base32(Str,Ptr,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base32(Str,Ptr,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base32(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
Result := AnsiDecode_Base32(Str,Ptr,Size,Reversed,AnsiEncodingTable_Base32,AnsiPaddingChar_Base32);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base32(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
Result := WideDecode_Base32(Str,Ptr,Size,Reversed,WideEncodingTable_Base32,WidePaddingChar_Base32);
end;

{------------------------------------------------------------------------------}

Function Decode_Base32(const Str: String; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char; PaddingChar: Char): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base32(Str,Size,Reversed,DecodingTable,PaddingChar);
{$ELSE}
Result := AnsiDecode_Base32(Str,Size,Reversed,DecodingTable,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base32(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar; PaddingChar: AnsiChar): Pointer;
var
  ResultSize: TDataSize;
begin
Size := AnsiDecodedLength_Base32(Str,False,PaddingChar);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := AnsiDecode_Base32(Str,Result,Size,Reversed,DecodingTable,PaddingChar);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('AnsiDecode_Base32: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Result := nil;
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base32(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): Pointer;
var
  ResultSize: TDataSize;
begin
Size := WideDecodedLength_Base32(Str,False,PaddingChar);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := WideDecode_Base32(Str,Result,Size,Reversed,DecodingTable,PaddingChar);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('WideDecode_Base32: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Result := nil;
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function Decode_Base32(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char; PaddingChar: Char): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base32(Str,Ptr,Size,Reversed,DecodingTable,PaddingChar);
{$ELSE}
Result := AnsiDecode_Base32(Str,Ptr,Size,Reversed,DecodingTable,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base32(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar; PaddingChar: AnsiChar): TDataSize;
var
  Buffer:         Byte;
  i:              TDataSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  StrPosition:    TStrSize;
begin
Result := AnsiDecodedLength_Base32(Str,False,PaddingChar);
DecodeCheckSize(Size,Result,32);
ResolveDataPointer(Ptr,Reversed,Size);
Remainder := 0;
RemainderBits := 0;
StrPosition := 1;
For i := 1 to Result do
  begin
    case RemainderBits of
      0:  begin
            Buffer := AnsiTableIndex(Str[StrPosition],DecodingTable,32) shl 3;
            Remainder := AnsiTableIndex(Str[StrPosition + 1],DecodingTable,32);
            Buffer := Buffer or (Remainder shr 2);
            Inc(StrPosition,2);
            Remainder := Remainder and $03;
            RemainderBits := 2;
          end;
      1:  begin
            Buffer := (Remainder shl 7) or (AnsiTableIndex(Str[StrPosition],DecodingTable,32) shl 2);
            Remainder := AnsiTableIndex(Str[StrPosition + 1],DecodingTable,32);
            Buffer := Buffer or (Remainder shr 3);
            Inc(StrPosition,2);
            Remainder := Remainder and $07;
            RemainderBits := 3;
          end;
      2:  begin
            Buffer := (Remainder shl 6) or (AnsiTableIndex(Str[StrPosition],DecodingTable,32) shl 1);
            Remainder := AnsiTableIndex(Str[StrPosition + 1],DecodingTable,32);
            Buffer := Buffer or (Remainder shr 4);
            Inc(StrPosition,2);
            Remainder := Remainder and $0F;
            RemainderBits := 4;
          end;
      3:  begin
            Buffer := (Remainder shl 5) or AnsiTableIndex(Str[StrPosition],DecodingTable,32);
            Inc(StrPosition,1);
            Remainder := 0;
            RemainderBits := 0;
          end;
      4:  begin
            Buffer := (Remainder shl 4) or (AnsiTableIndex(Str[StrPosition],DecodingTable,32) shr 1);
            Remainder := AnsiTableIndex(Str[StrPosition],DecodingTable,32) and $01;
            Inc(StrPosition,1);
            RemainderBits := 1;
          end;
    else
      raise EDecodingError.CreateFmt('AnsiDecode_Base32: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    PByte(Ptr)^ := Buffer;
    AdvanceDataPointer(Ptr,Reversed);
  end;
end;


{------------------------------------------------------------------------------}

Function WideDecode_Base32(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): TDataSize;
var
  Buffer:         Byte;
  i:              TDataSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  StrPosition:    TStrSize;
begin
Result := WideDecodedLength_Base32(Str,False,PaddingChar);
DecodeCheckSize(Size,Result,32);
ResolveDataPointer(Ptr,Reversed,Size);
Remainder := 0;
RemainderBits := 0;
StrPosition := 1;
For i := 1 to Result do
  begin
    case RemainderBits of
      0:  begin
            Buffer := WideTableIndex(Str[StrPosition],DecodingTable,32) shl 3;
            Remainder := WideTableIndex(Str[StrPosition + 1],DecodingTable,32);
            Buffer := Buffer or (Remainder shr 2);
            Inc(StrPosition,2);
            Remainder := Remainder and $03;
            RemainderBits := 2;
          end;
      1:  begin
            Buffer := (Remainder shl 7) or (WideTableIndex(Str[StrPosition],DecodingTable,32) shl 2);
            Remainder := WideTableIndex(Str[StrPosition + 1],DecodingTable,32);
            Buffer := Buffer or (Remainder shr 3);
            Inc(StrPosition,2);
            Remainder := Remainder and $07;
            RemainderBits := 3;
          end;
      2:  begin
            Buffer := (Remainder shl 6) or (WideTableIndex(Str[StrPosition],DecodingTable,32) shl 1);
            Remainder := WideTableIndex(Str[StrPosition + 1],DecodingTable,32);
            Buffer := Buffer or (Remainder shr 4);
            Inc(StrPosition,2);
            Remainder := Remainder and $0F;
            RemainderBits := 4;
          end;
      3:  begin
            Buffer := (Remainder shl 5) or WideTableIndex(Str[StrPosition],DecodingTable,32);
            Inc(StrPosition,1);
            Remainder := 0;
            RemainderBits := 0;
          end;
      4:  begin
            Buffer := (Remainder shl 4) or (WideTableIndex(Str[StrPosition],DecodingTable,32) shr 1);
            Remainder := WideTableIndex(Str[StrPosition],DecodingTable,32) and $01;
            Inc(StrPosition,1);
            RemainderBits := 1;
          end;
    else
      raise EDecodingError.CreateFmt('WideDecode_Base32: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    PByte(Ptr)^ := Buffer;
    AdvanceDataPointer(Ptr,Reversed);
  end;
end;

{------------------------------------------------------------------------------}

Function Decode_Base32Hex(const Str: String; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base32Hex(Str,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base32Hex(Str,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base32Hex(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base32(Str,Size,Reversed,AnsiEncodingTable_Base32Hex,AnsiPaddingChar_Base32Hex);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base32Hex(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
Result := WideDecode_Base32(Str,Size,Reversed,WideEncodingTable_Base32Hex,WidePaddingChar_Base32Hex);
end;

{------------------------------------------------------------------------------}

Function Decode_Base32Hex(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base32Hex(Str,Ptr,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base32Hex(Str,Ptr,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base32Hex(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
Result := AnsiDecode_Base32(Str,Ptr,Size,Reversed,AnsiEncodingTable_Base32Hex,AnsiPaddingChar_Base32Hex);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base32Hex(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
Result := WideDecode_Base32(Str,Ptr,Size,Reversed,WideEncodingTable_Base32Hex,WidePaddingChar_Base32Hex);
end;

{==============================================================================}

Function Decode_Base64(const Str: String; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base64(Str,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base64(Str,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base64(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base64(Str,Size,Reversed,AnsiEncodingTable_Base64,AnsiPaddingChar_Base64);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base64(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
Result := WideDecode_Base64(Str,Size,Reversed,WideEncodingTable_Base64,WidePaddingChar_Base64);
end;

{------------------------------------------------------------------------------}

Function Decode_Base64(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base64(Str,Ptr,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base64(Str,Ptr,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base64(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
Result := AnsiDecode_Base64(Str,Ptr,Size,Reversed,AnsiEncodingTable_Base64,AnsiPaddingChar_Base64);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base64(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
Result := WideDecode_Base64(Str,Ptr,Size,Reversed,WideEncodingTable_Base64,WidePaddingChar_Base64);
end;

{------------------------------------------------------------------------------}

Function Decode_Base64(const Str: String; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char; PaddingChar: Char): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base64(Str,Size,Reversed,DecodingTable,PaddingChar);
{$ELSE}
Result := AnsiDecode_Base64(Str,Size,Reversed,DecodingTable,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base64(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar; PaddingChar: AnsiChar): Pointer;
var
  ResultSize: TDataSize;
begin
Size := AnsiDecodedLength_Base64(Str,False,PaddingChar);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := AnsiDecode_Base64(Str,Result,Size,Reversed,DecodingTable,PaddingChar);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('AnsiDecode_Base64: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Result := nil;
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base64(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): Pointer;
var
  ResultSize: TDataSize;
begin
Size := WideDecodedLength_Base64(Str,False,PaddingChar);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := WideDecode_Base64(Str,Result,Size,Reversed,DecodingTable,PaddingChar);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('WideDecode_Base64: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Result := nil;
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function Decode_Base64(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char; PaddingChar: Char): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base64(Str,Ptr,Size,Reversed,DecodingTable,PaddingChar);
{$ELSE}
Result := AnsiDecode_Base64(Str,Ptr,Size,Reversed,DecodingTable,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base64(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar; PaddingChar: AnsiChar): TDataSize;
var
  Buffer:         Byte;
  i:              TDataSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  StrPosition:    TStrSize;
begin
Result := AnsiDecodedLength_Base64(Str,False,PaddingChar);
DecodeCheckSize(Size,Result,64);
ResolveDataPointer(Ptr,Reversed,Size);
Remainder := 0;
RemainderBits := 0;
StrPosition := 1;
For i := 1 to Result do
  begin
    case RemainderBits of
      0:  begin
            Buffer := AnsiTableIndex(Str[StrPosition],DecodingTable,64) shl 2;
            Remainder := AnsiTableIndex(Str[StrPosition + 1],DecodingTable,64);
            Buffer := Buffer or (Remainder shr 4);
            Inc(StrPosition,2);
            Remainder := Remainder and $0F;
            RemainderBits := 4;
          end;
      2:  begin
            Buffer := (Remainder shl 6) or AnsiTableIndex(Str[StrPosition],DecodingTable,64);
            Inc(StrPosition,1);
            Remainder := $00;
            RemainderBits := 0;
          end;
      4:  begin
            Buffer := (Remainder shl 4) or (AnsiTableIndex(Str[StrPosition],DecodingTable,64) shr 2);
            Remainder := AnsiTableIndex(Str[StrPosition],DecodingTable,64) and $03;
            Inc(StrPosition,1);
            RemainderBits := 2;
          end;
    else
      raise EDecodingError.CreateFmt('AnsiDecode_Base64: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    PByte(Ptr)^ := Buffer;
    AdvanceDataPointer(Ptr,Reversed);
  end;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base64(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar; PaddingChar: UnicodeChar): TDataSize;
var
  Buffer:         Byte;
  i:              TDataSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  StrPosition:    TStrSize;
begin
Result := WideDecodedLength_Base64(Str,False,PaddingChar);
DecodeCheckSize(Size,Result,64);
ResolveDataPointer(Ptr,Reversed,Size);
Remainder := 0;
RemainderBits := 0;
StrPosition := 1;
For i := 1 to Result do
  begin
    case RemainderBits of
      0:  begin
            Buffer := WideTableIndex(Str[StrPosition],DecodingTable,64) shl 2;
            Remainder := WideTableIndex(Str[StrPosition + 1],DecodingTable,64);
            Buffer := Buffer or (Remainder shr 4);
            Inc(StrPosition,2);
            Remainder := Remainder and $0F;
            RemainderBits := 4;
          end;
      2:  begin
            Buffer := (Remainder shl 6) or WideTableIndex(Str[StrPosition],DecodingTable,64);
            Inc(StrPosition,1);
            Remainder := $00;
            RemainderBits := 0;
          end;
      4:  begin
            Buffer := (Remainder shl 4) or (WideTableIndex(Str[StrPosition],DecodingTable,64) shr 2);
            Remainder := WideTableIndex(Str[StrPosition],DecodingTable,64) and $03;
            Inc(StrPosition,1);
            RemainderBits := 2;
          end;
    else
      raise EDecodingError.CreateFmt('WideDecode_Base64: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    PByte(Ptr)^ := Buffer;
    AdvanceDataPointer(Ptr,Reversed);
  end;
end;

{==============================================================================}

Function Decode_Base85(const Str: String; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base85(Str,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base85(Str,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base85(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base85(Str,Size,Reversed,AnsiEncodingTable_Base85,AnsiCompressionChar_Base85);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base85(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean = False): Pointer;
begin
Result := WideDecode_Base85(Str,Size,Reversed,WideEncodingTable_Base85,WideCompressionChar_Base85);
end;

{------------------------------------------------------------------------------}

Function Decode_Base85(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base85(Str,Ptr,Size,Reversed);
{$ELSE}
Result := AnsiDecode_Base85(Str,Ptr,Size,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base85(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
Result := AnsiDecode_Base85(Str,Ptr,Size,Reversed,AnsiEncodingTable_Base85,AnsiCompressionChar_Base85);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base85(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean = False): TDataSize;
begin
Result := WideDecode_Base85(Str,Ptr,Size,Reversed,WideEncodingTable_Base85,WideCompressionChar_Base85);
end;

{------------------------------------------------------------------------------}

Function Decode_Base85(const Str: String; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char; CompressionChar: Char): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base85(Str,Size,Reversed,DecodingTable,CompressionChar);
{$ELSE}
Result := AnsiDecode_Base85(Str,Size,Reversed,DecodingTable,CompressionChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base85(const Str: AnsiString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar; CompressionChar: AnsiChar): Pointer;
var
  ResultSize: TDataSize;
begin
Size := AnsiDecodedLength_Base85(Str,False,CompressionChar);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := AnsiDecode_Base85(Str,Result,Size,Reversed,DecodingTable,CompressionChar);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('AnsiDecode_Base85: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Result := nil;
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base85(const Str: UnicodeString; out Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar; CompressionChar: UnicodeChar): Pointer;
var
  ResultSize: TDataSize;
begin
Size := WideDecodedLength_Base85(Str,False,CompressionChar);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := WideDecode_Base85(Str,Result,Size,Reversed,DecodingTable,CompressionChar);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('WideDecode_Base85: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Result := nil;
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function Decode_Base85(const Str: String; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of Char; CompressionChar: Char): TDataSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base85(Str,Ptr,Size,Reversed,DecodingTable,CompressionChar);
{$ELSE}
Result := AnsiDecode_Base85(Str,Ptr,Size,Reversed,DecodingTable,CompressionChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base85(const Str: AnsiString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of AnsiChar; CompressionChar: AnsiChar): TDataSize;
var
  i:            TDataSize;
  j:            Integer;
  Buffer:       LongWord;
  Buffer64:     Int64;
  StrPosition:  TStrSize;
begin
Result := AnsiDecodedLength_Base85(Str,False,CompressionChar);
DecodeCheckSize(Size,Result,85,3);
If Size < Result then Result := Size;
ResolveDataPointer(Ptr,Reversed,Size,4);
StrPosition := 1;
For i := 1 to Ceil(Result / 4) do
  begin
    If Str[StrPosition] = CompressionChar then
      begin
        Buffer := $00000000;
        Inc(StrPosition);
      end
    else
      begin
        Buffer64 := 0;
        For j := 0 to 4 do
          If (StrPosition + j) <= Length(Str) then
            Buffer64 := Buffer64 + (Int64(AnsiTableIndex(Str[StrPosition + j],DecodingTable,85)) * Coefficients_Base85[j + 1])
          else
            Buffer64 := Buffer64 + (Int64(84) * Coefficients_Base85[j + 1]);
        If Buffer64 > High(LongWord) then
          raise EDecodingError.CreateFmt('AnsiDecode_Base85: Invalid value decoded (%d).',[Buffer64]);
        Buffer := LongWord(Buffer64);
        Inc(StrPosition,5);
      end;
    If not Reversed then SwapByteOrder(Buffer);
    If (i * 4) > Result  then
      begin
        If Reversed then
          Move({%H-}Pointer(PtrUInt(@Buffer) - PtrUInt(Result and 3) + 4)^,{%H-}Pointer(PtrUInt(Ptr) - PtrUInt(Result and 3) + 4)^,Result and 3)
        else
          Move(Buffer,Ptr^,Result and 3);
      end
    else PLongWord(Ptr)^ := Buffer;
    AdvanceDataPointer(Ptr,Reversed,4);
  end;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base85(const Str: UnicodeString; Ptr: Pointer; Size: TDataSize; Reversed: Boolean; const DecodingTable: Array of UnicodeChar; CompressionChar: UnicodeChar): TDataSize;
var
  i:            TDataSize;
  j:            Integer;
  Buffer:       LongWord;
  Buffer64:     Int64;
  StrPosition:  TStrSize;
begin
Result := WideDecodedLength_Base85(Str,False,CompressionChar);
DecodeCheckSize(Size,Result,85,3);
If Size < Result then Result := Size;
ResolveDataPointer(Ptr,Reversed,Size,4);
StrPosition := 1;
For i := 1 to Ceil(Result / 4) do
  begin
    If Str[StrPosition] = CompressionChar then
      begin
        Buffer := $00000000;
        Inc(StrPosition);
      end
    else
      begin
        Buffer64 := 0;
        For j := 0 to 4 do
          If (StrPosition + j) <= Length(Str) then
            Buffer64 := Buffer64 + (Int64(WideTableIndex(Str[StrPosition + j],DecodingTable,85)) * Coefficients_Base85[j + 1])
          else
            Buffer64 := Buffer64 + (Int64(84) * Coefficients_Base85[j + 1]);
        If Buffer64 > High(LongWord) then
          raise EDecodingError.CreateFmt('WideDecode_Base85: Invalid value decoded (%d).',[Buffer64]);
        Buffer := LongWord(Buffer64);
        Inc(StrPosition,5);
      end;
    If not Reversed then SwapByteOrder(Buffer);
    If (i * 4) > Result  then
      begin
        If Reversed then
          Move({%H-}Pointer(PtrUInt(@Buffer) - PtrUInt(Result and 3) + 4)^,{%H-}Pointer(PtrUInt(Ptr) - PtrUInt(Result and 3) + 4)^,Result and 3)
        else
          Move(Buffer,Ptr^,Result and 3);
      end
    else PLongWord(Ptr)^ := Buffer;
    AdvanceDataPointer(Ptr,Reversed,4);
  end;
end;

end.

