{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Binary to text encodings

  ©František Milt 2018-05-12

  Version 1.1.5

  Notes:
    - Do not call EncodedLength function with Base85 or Ascii85 encoding.
    - Hexadecimal encoding is always forward (ie. not reversed) when executed by
      a universal function, irrespective of selected setting.
    - Base16, Base32 nad Base64 encodings should be compliant with RFC 4648.
    - Base85 encoding is by-default using Z85 alphabet with undescore ("_", #95)
      as an all-zero compression letter.

  Dependencies:
    AuxTypes - github.com/ncs-sniper/Lib.AuxTypes

===============================================================================}
unit BinTextEnc;

{$IFDEF FPC}
  {$MODE ObjFPC}
  {$INLINE ON}
  {$DEFINE CanInline}
  {$DEFINE FPC_DisableWarns}
  {$MACRO ON}
{$ELSE}
  {$IF CompilerVersion >= 17 then}  // Delphi 2005+
    {$DEFINE CanInline}
  {$ELSE}
    {$UNDEF CanInline}
  {$IFEND}  
{$ENDIF}
{$H+}

interface

uses
  SysUtils, Classes,
  AuxTypes, AuxClasses;

type
  EBTEException = class(Exception);

  EBTEInvalidValue = class(EBTEException);
  EBTEInvalidState = class(EBTEException);

  EBTETooMuchData    = class(EBTEException);
  EBTEBufferTooSmall = class(EBTEException);

  EBTEProcessingError = class(EBTEException);

{===============================================================================
--------------------------------------------------------------------------------
                                 TBTETranscoder
--------------------------------------------------------------------------------
===============================================================================}
type
  TBTEEncoding = (encUnknown,encBase2,encBase8,encBase10,encBase16,
                  encHexadecimal,encBase32,encBase32Hex,encBase64,encBase85,
                  encAscii85);

  TBTEEncodingFeature = (efPadding,efCompression,efReversible,efOutputSize,
                         efSlowOutputSize);

  TBTEEncodingFeatures = set of TBTEEncodingFeature;

  TBTEEncodingTable = array of Char;

  TBTEDecodingTable = array[0..127] of Byte;

{===============================================================================
    TBTETranscoder - class declaration
===============================================================================}
type
  TBTETranscoder = class(TCustomObject)
  protected
    fEncodedString:       String;
    fIsProcessing:        Boolean;
    fBreakProcessing:     Boolean;
    // encoding settings
    fHeader:              Boolean;
    fPadding:             Boolean;
    fPaddingChar:         Char;
    fCompression:         Boolean;
    fCompressionChar:     Char;
    fReversed:            Boolean;
    // processing variables
    fEncodedStringPos:    TStrOff;
    // events
    fProgressCoef:        Integer;
    fOnProgressEvent:     TFloatEvent;
    fOnProgressCallback:  TFloatCallback;
    // getters/setters
    Function GetEncodedString: String; virtual;
    procedure SetEncodedString(const Value: String); virtual;
    procedure SetPadding(Value: Boolean); virtual;
    procedure SetPaddingChar(Value: Char); virtual;
    procedure SetCompression(Value: Boolean); virtual;
    procedure SetCompressionChar(Value: Char); virtual;
    procedure SetReversed(Value: Boolean); virtual;
    procedure SetHeader(Value: Boolean); virtual;
    // events firing
    procedure DoProgress(Progress: Double); virtual;
    // initialization, finalization
    procedure InitializeTable; virtual; abstract;
    procedure Initialize; virtual;
    procedure Finalize; virtual;
  public
  {
    DataLimit returns maximum number of bytes that can be processed by a
    particular encoder.
    If you try to encode or even get encoded length for more data, an
    EBTETooMuchData exception will be raised.

    This limit is here to prevent potential out-of-memory errors and severe
    rounding errors in some calculations when encoding.

    Note that this limit changes for each encoding, and is selected so that
    encoded string can reach a maximum of about 512M characters in length.
  }
    class Function DataLimit: TMemSize; virtual; abstract;
  {
    CharLimit sets limit on how long a string can be assigned to property
    EncodedString. If you try to assign longer string, an EBTETooMuchData
    exception will be raised.

    Currently it is always 512M characters.
  }
    class Function CharLimit: TStrSize; virtual;
    class Function Encoding: TBTEEncoding; virtual; abstract;
    class Function EncodingFeatures: TBTEEncodingFeatures; virtual; abstract;
    class Function EncodingTableLength: Integer; virtual; abstract;
    class Function HeaderLength: TStrSize; virtual;
    class Function HeaderPresent(const EncodedString: String): Boolean; virtual;
    class Function HeaderNumberExtract(const EncodedString: String; out HeaderNumber: UInt16): Boolean; virtual;
    class Function HeaderEncoding(const EncodedString: String): TBTEEncoding; virtual;
    class Function HeaderReversed(const EncodedString: String): Boolean; virtual;
    class Function EncodingTableIsValid(const EncodingTable: TBTEEncodingTable): Boolean; virtual;
    constructor Create;
    destructor Destroy; override;
    Function BreakProcessing: Boolean; virtual;
    // properties
    property EncodedString: String read GetEncodedString write SetEncodedString;
    property IsProcessing: Boolean read fIsProcessing;
    property Header: Boolean read fHeader write SetHeader;
    property Padding: Boolean read fPadding write SetPadding;
    property PaddingCharacter: Char read fPaddingChar write SetPaddingChar;
    property Compression: Boolean read fCompression write SetCompression;
    property CompressionCharacter: Char read fCompressionChar write SetCompressionChar;
    property Reversed: Boolean read fReversed write SetReversed;
    property ProgressCoefficient: Integer read fProgressCoef write fProgressCoef;
    property OnProgressEvent: TFloatEvent read fOnProgressEvent write fOnProgressEvent;
    property OnProgressCallback: TFloatCallback read fOnProgressCallback write fOnProgressCallback;
    property OnProgress: TFloatEvent read fOnProgressEvent write fOnProgressEvent;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                                  TBTEEncoder
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TBTEEncoder - class declaration
===============================================================================}
type
  TBTEEncoder = class(TBTETranscoder)
  protected
    fEncodingTable: TBTEEncodingTable;
    Function GetEncodingTable: TBTEEncodingTable; virtual;
    procedure SetEncodingTable(const Value: TBTEEncodingTable); virtual;
    procedure AssignEncodingTable(const EncodingTable: array of Char); virtual;
    // processing
    procedure WriteHeader; virtual;
    procedure WriteChar(C: Char); virtual;
    procedure WritePadding; virtual;
    procedure Encode(const Buffer; Size: TMemSize); virtual;
    procedure EncodeSpecific(const Buffer; Size: TMemSize); virtual; abstract;
  public
    // resulting string length
    Function EncodedLengthFromBuffer(const Buffer; Size: TMemSize): TStrSize; virtual; abstract;
    Function EncodedLengthFromMemory(Mem: Pointer; Size: TMemSize): TStrSize; virtual;
    Function EncodedLengthFromStream(Stream: TStream; Count: Int64 = -1): TStrSize; virtual;
    Function EncodedLengthFromFile(const FileName: String): TStrSize; virtual;
    // processing
    procedure EncodeFromBuffer(const Buffer; Size: TMemSize); virtual;
    procedure EncodeFromMemory(Mem: Pointer; Size: TMemSize); virtual;
    procedure EncodeFromStream(Stream: TStream; Count: Int64 = -1); virtual;
    procedure EncodeFromFile(const FileName: String); virtual;
    property EncodingTable: TBTEEncodingTable read GetEncodingTable write SetEncodingTable;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                                  TBTEDecoder
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TBTEDecoder - class declaration
===============================================================================}
type
  TBTEDecoder = class(TBTETranscoder)
  protected
    fDecodingTable: TBTEDecodingTable;
    // processing
    procedure ReadHeader; virtual;  // sets properties Header and Reversed (if header is present)
    Function ReadChar: Char; virtual;
    Function ResolveChar(C: Char): Byte; virtual;
    Function CountPadding: TStrSize; virtual;
    procedure Decode(const Buffer; Size: TMemSize); virtual;
    procedure DecodeSpecific(const Buffer; Size: TMemSize); virtual; abstract;
  public
    procedure ConstructDecodingTable(const EncodingTable: TBTEEncodingTable); virtual;
    // resulting data size
    Function DecodedSize: TMemSize; virtual; abstract;  // sets properties Padding and Compressed
    //processing
    Function DecodeIntoBuffer(const Buffer; Size: TMemSize): TMemSize; virtual;
    Function DecodeIntoMemory(Mem: Pointer; Size: TMemSize): TMemSize; overload; virtual;
    Function DecodeIntoMemory(out Mem: Pointer): TMemSize; overload; virtual;
    Function DecodeIntoStream(Stream: TStream): TMemSize; virtual;
    Function DecodeIntoFile(const FileName: String): TMemSize; virtual;
    property DecodingTable: TBTEDecodingTable read fDecodingTable write fDecodingTable;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                                 TBase2Encoder
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TBase2Encoder - class declaration
===============================================================================}
type
  TBase2Encoder = class(TBTEEncoder)
  protected
    procedure InitializeTable; override;
    procedure EncodeSpecific(const Buffer; Size: TMemSize); override;
  public
    class Function DataLimit: TMemSize; override;
    class Function Encoding: TBTEEncoding; override;
    class Function EncodingFeatures: TBTEEncodingFeatures; override;
    class Function EncodingTableLength: Integer; override;
    Function EncodedLengthFromBuffer(const Buffer; Size: TMemSize): TStrSize; override;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                                 TBase2Decoder
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TBase2Decoder - class declaration
===============================================================================}
type
  TBase2Decoder = class(TBTEDecoder)
  protected
    procedure InitializeTable; override;
    procedure DecodeSpecific(const Buffer; Size: TMemSize); override;
  public
    class Function DataLimit: TMemSize; override;
    class Function Encoding: TBTEEncoding; override;
    class Function EncodingFeatures: TBTEEncodingFeatures; override;
    class Function EncodingTableLength: Integer; override;
    Function DecodedSize: TMemSize; override;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                                 TBase64Encoder
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TBase64Encoder - class declaration
===============================================================================}
type
  TBase64Encoder = class(TBTEEncoder)
  protected
    procedure InitializeTable; override;
    procedure EncodeSpecific(const Buffer; Size: TMemSize); override;
  public
    class Function DataLimit: TMemSize; override;
    class Function Encoding: TBTEEncoding; override;
    class Function EncodingFeatures: TBTEEncodingFeatures; override;
    class Function EncodingTableLength: Integer; override;
    Function EncodedLengthFromBuffer(const Buffer; Size: TMemSize): TStrSize; override;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                                 TBase64Decoder
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TBase64Decoder - class declaration
===============================================================================}
type
  TBase64Decoder = class(TBTEDecoder)
  protected
    procedure InitializeTable; override;
    procedure DecodeSpecific(const Buffer; Size: TMemSize); override;
  public
    class Function DataLimit: TMemSize; override;
    class Function Encoding: TBTEEncoding; override;
    class Function EncodingFeatures: TBTEEncodingFeatures; override;
    class Function EncodingTableLength: Integer; override;
    Function DecodedSize: TMemSize; override;
  end;

implementation

uses
  Math,
  StrRect;

{===============================================================================
    Implementation constants and functions
===============================================================================}
// constants for encoded string headers
const
  BTE_HEADER_ENCODING_BASE2   = 1;
  BTE_HEADER_ENCODING_BASE8   = 2;
  BTE_HEADER_ENCODING_BASE10  = 3;
  BTE_HEADER_ENCODING_BASE16  = 4;
  BTE_HEADER_ENCODING_HEX     = 5;
  BTE_HEADER_ENCODING_BASE32  = 6;
  BTE_HEADER_ENCODING_BASE32H = 7;
  BTE_HEADER_ENCODING_BASE64  = 8;
  BTE_HEADER_ENCODING_BASE85  = 9;
  BTE_HEADER_ENCODING_BASE85A = 10;

  BTE_HEADER_FLAG_REVERSED   = $0100;

//------------------------------------------------------------------------------  

Function CharInSet(C: Char; S: TSysCharSet): Boolean;
begin
{$IF SizeOf(Char) <> 1}
If Ord(C) > 255 then
  Result := False
else
{$IFEND}
  Result := AnsiChar(C) in S;
end;

//------------------------------------------------------------------------------

Function ResolveDataPointer(Ptr: Pointer; Size: TMemSize; Reversed: Boolean; RevOffset: UInt32 = 1): Pointer;
begin
If Reversed then
  Result := Pointer(PtrUInt(Ptr) + (PtrUInt(Size) - PtrUInt(RevOffset)))
else
  Result := Ptr;
end;

//------------------------------------------------------------------------------

procedure AdvanceDataPointer(var Ptr: Pointer; Reversed: Boolean);
begin
If Reversed then
  Ptr := Pointer(PtrUInt(Ptr) - 1)
else
  Ptr := Pointer(PtrUInt(Ptr) + 1);
end;


{===============================================================================
--------------------------------------------------------------------------------
                                 TBTETranscoder                                 
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TBTETranscoder - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TBTETranscoder - protected methods
-------------------------------------------------------------------------------}

Function TBTETranscoder.GetEncodedString: String;
begin
If not fIsProcessing then
  Result := fEncodedString
else
  raise EBTEInvalidState.Create('TBTETranscoder.GetEncodedString: Cannot get encoded string, transcoder is running.');
end;

//------------------------------------------------------------------------------

procedure TBTETranscoder.SetEncodedString(const Value: String);
begin
If not fIsProcessing then
  begin
    If Length(Value) <= CharLimit then
      fEncodedString := Value
    else
      raise EBTETooMuchData.CreateFmt('TBTETranscoder.SetEncodedString: Encoded string too long (%d characters).',[Length(Value)]);
  end
else raise EBTEInvalidState.Create('TBTETranscoder.SetEncodedString: Cannot set encoded string, transcoder is running.');
end;

//------------------------------------------------------------------------------

procedure TBTETranscoder.SetHeader(Value: Boolean);
begin
If not fIsProcessing then
  fHeader := Value
else
  raise EBTEInvalidState.Create('TBTETranscoder.SetHeader: Cannot change settings, transcoder is running.');
end;

//------------------------------------------------------------------------------

procedure TBTETranscoder.SetPadding(Value: Boolean);
begin
If not fIsProcessing then
  begin
    If efPadding in EncodingFeatures then
      fPadding := Value
    else
      fPadding := False;
  end
else raise EBTEInvalidState.Create('TBTETranscoder.SetPadding: Cannot change settings, transcoder is running.');
end;

//------------------------------------------------------------------------------

procedure TBTETranscoder.SetPaddingChar(Value: Char);
begin
If not fIsProcessing then
  begin
    If efPadding in EncodingFeatures then
      fPaddingChar := Value
    else
      fPaddingChar := #0;
  end
else raise EBTEInvalidState.Create('TBTETranscoder.SetPaddingChar: Cannot change settings, transcoder is running.');
end;

//------------------------------------------------------------------------------

procedure TBTETranscoder.SetCompression(Value: Boolean);
begin
If not fIsProcessing then
  begin
    If efCompression in EncodingFeatures then
      fCompression := Value
    else
      fCompression := False;
  end
else raise EBTEInvalidState.Create('TBTETranscoder.SetCompression: Cannot change settings, transcoder is running.');
end;

//------------------------------------------------------------------------------

procedure TBTETranscoder.SetCompressionChar(Value: Char);
begin
If not fIsProcessing then
  begin
    If efCompression in EncodingFeatures then
      fCompressionChar := Value
    else
      fCompressionChar := #0;
  end
else raise EBTEInvalidState.Create('TBTETranscoder.SetCompressionChar: Cannot change settings, transcoder is running.');
end;

//------------------------------------------------------------------------------

procedure TBTETranscoder.SetReversed(Value: Boolean);
begin
If not fIsProcessing then
  begin
    If efReversible in EncodingFeatures then
      fReversed := Value
    else
      fReversed := False;
  end
else raise EBTEInvalidState.Create('TBTETranscoder.SetReversed: Cannot change settings, transcoder is running.');
end;

//------------------------------------------------------------------------------

procedure TBTETranscoder.DoProgress(Progress: Double);
begin
If Assigned(fOnProgressEvent) then
  fOnProgressEvent(Self,Progress);
If Assigned(fOnProgressCallback) then
  fOnProgressCallback(Self,Progress);
end;

//------------------------------------------------------------------------------

procedure TBTETranscoder.Initialize;
begin
fEncodedString := '';
fIsProcessing := False;
fBreakProcessing := False;
fHeader := False;
fPadding := False;
fPaddingChar := #0;
fCompression := False;
fCompressionChar := #0;
fReversed := False;
fEncodedStringPos := 0;
fProgressCoef := 1024;
fOnProgressEvent := nil;
fOnProgressCallback := nil;
InitializeTable;
end;

//------------------------------------------------------------------------------

procedure TBTETranscoder.Finalize;
begin
fOnProgressEvent := nil;
fOnProgressCallback := nil;
end;

{-------------------------------------------------------------------------------
    TBTETranscoder - public methods
-------------------------------------------------------------------------------}

class Function TBTETranscoder.CharLimit: TStrSize;
begin
Result := 512 * 1024 * 1024;  // about 1GiB for unicode/wide string
end;

//------------------------------------------------------------------------------

class Function TBTETranscoder.HeaderLength: TStrSize;
begin
{
  Header has the following format:

    #xxxx~

  ... where xxxx is a four-digit hexadecimal number containing encoding type
  and some other settings. It is directly followed by the encoded string.

  This means the header has always the same length.
}
Result := 6;
end;

//------------------------------------------------------------------------------

class Function TBTETranscoder.HeaderPresent(const EncodedString: String): Boolean;
var
  i:  TStrOff;
begin
// first check if the header can actually fit into the string (ie. the string is long enough)
If Length(EncodedString) >= HeaderLength then
  begin
    // check that the first character is a cross (#) and sixth is a vawe (~)
    If (EncodedString[1] = '#') and (EncodedString[6] = '~') then
      begin
        Result := True;
        // and now check that the four chars between can be a hex number
        For i := 2 to 5 do
          If not CharInSet(EncodedString[i],['0'..'9','a'..'f','A'..'F']) then
            begin
              Result := False;
              Break{For i};
            end;
      end
    else Result := False;
  end
else Result := False;
end;

//------------------------------------------------------------------------------

class Function TBTETranscoder.HeaderNumberExtract(const EncodedString: String; out HeaderNumber: UInt16): Boolean;
var
  Temp: Integer;
begin
{
  Header number format

    bits          meaning
  -------------------------------------
     0.. 6        encoding number
         7        reserved
         8        reversed data flag
     9..15        reserved

  BTE_HEADER_FLAG_REVERSED   = $0100;
}
If HeaderPresent(EncodedString) then
  begin
    If TryStrToInt('$' + Copy(EncodedString,2,4),Temp) then
      begin
        HeaderNumber := UInt16(Temp);
        Result := True;
      end
    else Result := False;
  end
else Result := False;
end;

//------------------------------------------------------------------------------

class Function TBTETranscoder.HeaderEncoding(const EncodedString: String): TBTEEncoding;
var
  HeaderNumber: Word;
begin
If HeaderNumberExtract(EncodedString,HeaderNumber) then
  case HeaderNumber and $7F of
    BTE_HEADER_ENCODING_BASE2:    Result := encBase2;
    BTE_HEADER_ENCODING_BASE8:    Result := encBase8;
    BTE_HEADER_ENCODING_BASE10:   Result := encBase10;
    BTE_HEADER_ENCODING_BASE16:   Result := encBase16;
    BTE_HEADER_ENCODING_HEX:      Result := encHexadecimal;
    BTE_HEADER_ENCODING_BASE32:   Result := encBase32;
    BTE_HEADER_ENCODING_BASE32H:  Result := encBase32Hex;
    BTE_HEADER_ENCODING_BASE64:   Result := encBase64;
    BTE_HEADER_ENCODING_BASE85:   Result := encBase85;
    BTE_HEADER_ENCODING_BASE85A:  Result := encAscii85;
  else
    Result := encUnknown;
  end
else Result := encUnknown;
end;

//------------------------------------------------------------------------------

class Function TBTETranscoder.HeaderReversed(const EncodedString: String): Boolean;
var
  HeaderNumber: Word;
begin
If HeaderNumberExtract(EncodedString,HeaderNumber) then
  Result := (HeaderNumber and BTE_HEADER_FLAG_REVERSED) <> 0
else
  Result := False;
end;

//------------------------------------------------------------------------------

class Function TBTETranscoder.EncodingTableIsValid(const EncodingTable: TBTEEncodingTable): Boolean;
var
  i,j:  Integer;
begin
{
  Check length of the table, that all chars have ordinal values lower or equal
  to 127 and also that there are no repeats.
}
Result := False;
If Length(EncodingTable) = EncodingTableLength then
  begin
    For i := Low(EncodingTable) to High(EncodingTable) do
      If Ord(EncodingTable[i]) <= 127 then
        begin
          For j := Succ(i) to High(EncodingTable) do
            If EncodingTable[i] = EncodingTable[j] then
              Exit;
        end
      else Exit;
  end;
Result := True;
end;

//------------------------------------------------------------------------------

constructor TBTETranscoder.Create;
begin
inherited Create;
Initialize;
end;

//------------------------------------------------------------------------------

destructor TBTETranscoder.Destroy;
begin
Finalize;
inherited;
end;

//------------------------------------------------------------------------------

Function TBTETranscoder.BreakProcessing: Boolean;
begin
Result := fBreakProcessing;
fBreakProcessing := True;
end;     


{===============================================================================
--------------------------------------------------------------------------------
                                  TBTEEncoder
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TBTEEncoder - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TBTEEncoder - protected methods
-------------------------------------------------------------------------------}

Function TBTEEncoder.GetEncodingTable: TBTEEncodingTable;
begin
Result := Copy(fEncodingTable);
end;

//------------------------------------------------------------------------------

procedure TBTEEncoder.SetEncodingTable(const Value: TBTEEncodingTable);
begin
If not fIsProcessing then
  begin
    // check validity of the table
    If EncodingTableIsValid(Value) then
      fEncodingTable := Copy(Value)
    else
      raise EBTEInvalidValue.Create('TBTEEncoder.SetEncodingTable: Invalid encoding table.');
  end
else raise EBTEInvalidState.Create('TBTEEncoder.SetEncodingTable: Cannot set encoding table, encoder is running.');
end;

//------------------------------------------------------------------------------

procedure TBTEEncoder.AssignEncodingTable(const EncodingTable: array of Char);
var
  i:  Integer;
begin
SetLength(fEncodingTable,Length(EncodingTable));
For i := Low(EncodingTable) to High(EncodingTable) do
  fEncodingTable[i] := EncodingTable[i];
end;

//------------------------------------------------------------------------------

procedure TBTEEncoder.WriteHeader;

  Function CalculateHeaderNumber: Word;
  begin
    // encoding number
    case Encoding of
      encBase2:       Result := BTE_HEADER_ENCODING_BASE2;
      encBase8:       Result := BTE_HEADER_ENCODING_BASE8;
      encBase10:      Result := BTE_HEADER_ENCODING_BASE10;
      encBase16:      Result := BTE_HEADER_ENCODING_BASE16;
      encHexadecimal: Result := BTE_HEADER_ENCODING_HEX;
      encBase32:      Result := BTE_HEADER_ENCODING_BASE32;
      encBase32Hex:   Result := BTE_HEADER_ENCODING_BASE32H;
      encBase64:      Result := BTE_HEADER_ENCODING_BASE64;
      encBase85:      Result := BTE_HEADER_ENCODING_BASE85;
      encAscii85:     Result := BTE_HEADER_ENCODING_BASE85A;
    else
      raise EBTEInvalidValue.CreateFmt('TBTEEncoder.OutputHeader.CalculateHeaderNumber: Invalid encoding (%d).',[Ord(Encoding)]);
    end;
    // flags
    If fReversed and (efReversible in EncodingFeatures) then
      Result := Result or BTE_HEADER_FLAG_REVERSED;
  end;

begin
fEncodedString := Format('#%.4x~',[CalculateHeaderNumber]);
fEncodedStringPos := Succ(HeaderLength);
end;

//------------------------------------------------------------------------------

procedure TBTEEncoder.WriteChar(C: Char);
begin
If fEncodedStringPos <= Length(fEncodedString) then
  begin
    // progress
    If ((fEncodedStringPos mod fProgressCoef) = 0) and (Length(fEncodedString) > 0) then
      DoProgress(Pred(fEncodedStringPos) / Length(fEncodedString));
    fEncodedString[fEncodedStringPos] := C;
    Inc(fEncodedStringPos);
  end
else raise EBTEProcessingError.Create('TBTEEncoder.WriteChar: Invalid string position.',);
end;

//------------------------------------------------------------------------------

procedure TBTEEncoder.WritePadding;
begin
while fEncodedStringPos <= Length(fEncodedString) do
  WriteChar(fPaddingChar);
end;

//------------------------------------------------------------------------------

procedure TBTEEncoder.Encode(const Buffer; Size: TMemSize);
begin
fBreakProcessing := False;
fIsProcessing := True;
try
  fEncodedStringPos := 1;
  // write header
  If fHeader then
    WriteHeader;
  // preallocate encoded string (note that it may already contain the header)
  SetLength(fEncodedString,EncodedLengthFromBuffer(Buffer,Size));
  DoProgress(0.0);
  // encoding-specific processing
  EncodeSpecific(Buffer,Size);
  DoProgress(1.0);
finally
  fIsProcessing := False;
end;
end;

{-------------------------------------------------------------------------------
    TBTEEncoder - public methods
-------------------------------------------------------------------------------}

Function TBTEEncoder.EncodedLengthFromMemory(Mem: Pointer; Size: TMemSize): TStrSize;
begin
Result := EncodedLengthFromBuffer(Mem^,Size);
end;

//------------------------------------------------------------------------------

Function TBTEEncoder.EncodedLengthFromStream(Stream: TStream; Count: Int64 = -1): TStrSize;
var
  Buffer:     Pointer;
  BytesRead:  Integer;
begin
If Assigned(Stream) then
  begin
    If Count = 0 then
      Count := Stream.Size - Stream.Position;
    If Count < 0 then
      begin
        Stream.Seek(0,soBeginning);
        Count := Stream.Size;
      end;  
    If Stream.Size <= DataLimit then
      begin
        If efSlowOutputSize in EncodingFeatures then
          begin
            // slow output size (the entire data must be scanned)
            If not(Stream is TCustomMemoryStream) then
              begin
                GetMem(Buffer,Count);
                try
                  BytesRead := Stream.Read(Buffer^,Count);
                  Result := EncodedLengthFromBuffer(Buffer^,TMemSize(BytesRead));
                finally
                  FreeMem(Buffer,Count);
                end;              
              end
            else Result := EncodedLengthFromBuffer(Pointer(PtrUInt(TCustomMemoryStream(Stream).Memory) + PtrUInt(Stream.Position))^,TMemSize(Count));
          end
        else Result := EncodedLengthFromBuffer(nil^,TMemSize(Count));
      end
    else raise EBTETooMuchData.CreateFmt('TBTEEncoder.EncodedLengthFromStream: Too much data (%d bytes).',[Stream.Size]);
  end
else raise EBTEInvalidValue.Create('TBTEEncoder.EncodedLengthFromStream: Stream not assigned.');
end;

//------------------------------------------------------------------------------

Function TBTEEncoder.EncodedLengthFromFile(const FileName: String): TStrSize;
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenRead or fmShareDenyNone);
try
  Result := EncodedLengthFromStream(FileStream);
finally
  FileStream.Free;
end;
end;

//------------------------------------------------------------------------------

procedure TBTEEncoder.EncodeFromBuffer(const Buffer; Size: TMemSize);
begin
If Size <= DataLimit then
  Encode(Buffer,Size)
else
  raise EBTETooMuchData.CreateFmt('TBTEEncoder.EncodeFromBuffer: Too much data (%d bytes).',[Size]);
end;

//------------------------------------------------------------------------------

procedure TBTEEncoder.EncodeFromMemory(Mem: Pointer; Size: TMemSize);
begin
If Size <= DataLimit then
  Encode(Mem^,Size)
else
  raise EBTETooMuchData.CreateFmt('TBTEEncoder.EncodeFromMemory: Too much data (%d bytes).',[Size]);
end;

//------------------------------------------------------------------------------

procedure TBTEEncoder.EncodeFromStream(Stream: TStream; Count: Int64 = -1);
var
  Buffer:     Pointer;
  BytesRead:  Integer;
begin
If Assigned(Stream) then
  begin
    If Count = 0 then
      Count := Stream.Size - Stream.Position;
    If Count < 0 then
      begin
        Stream.Seek(0,soBeginning);
        Count := Stream.Size;
      end; 
    If Count <= DataLimit then
      begin
        If not(Stream is TCustomMemoryStream) then
          begin
            // not a memory stream, load all data into buffer and process them there
            GetMem(Buffer,Count);
            try
              BytesRead := Stream.Read(Buffer^,Count);
              Encode(Buffer^,TMemSize(BytesRead));
            finally
              FreeMem(Buffer,Count);
            end;
          end
        else Encode(Pointer(PtrUInt(TCustomMemoryStream(Stream).Memory) + PtrUInt(Stream.Position))^,TMemSize(Count));
      end
    else raise EBTETooMuchData.CreateFmt('TBTEEncoder.EncodeFromStream: Too much data (%d bytes).',[Stream.Size]);
  end
else raise EBTEInvalidValue.Create('TBTEEncoder.EncodeFromStream: Stream not assigned.');
end;

//------------------------------------------------------------------------------

procedure TBTEEncoder.EncodeFromFile(const FileName: String);
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenRead or fmShareDenyWrite);
try
  EncodeFromStream(FileStream);
finally
  FileStream.Free;
end;
end;


{===============================================================================
--------------------------------------------------------------------------------
                                  TBTEDecoder
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TBTEDecoder - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TBTEDecoder - protected methods
-------------------------------------------------------------------------------}

procedure TBTEDecoder.ReadHeader;
var
  StrEncoding:  TBTEEncoding;
begin
fHeader := HeaderPresent(fEncodedString);
// if header is not present, leave current encoding settings
If fHeader then
  begin
    StrEncoding := HeaderEncoding(fEncodedString);
    If StrEncoding = Encoding then
      begin
        If efReversible in EncodingFeatures then
          fReversed := HeaderReversed(fEncodedString)
        else
          fReversed := False;
      end
    else raise EBTEProcessingError.CreateFmt('TBTEDecoder.ReadHeader: String has different encoding (%d).',[Ord(StrEncoding)]);
  end;
end;

//------------------------------------------------------------------------------

Function TBTEDecoder.ReadChar: Char;
begin
If fEncodedStringPos <= Length(fEncodedString) then
  begin
    // progress
    If ((fEncodedStringPos mod fProgressCoef) = 0) and (Length(fEncodedString) > 0) then
      DoProgress(Pred(fEncodedStringPos) / Length(fEncodedString));
    Result := fEncodedString[fEncodedStringPos];
    Inc(fEncodedStringPos);
  end
else raise EBTEProcessingError.Create('TBTEDecoder.ReadChar: Invalid string position.',);
end;

//------------------------------------------------------------------------------

Function TBTEDecoder.ResolveChar(C: Char): Byte;
begin
If Ord(C) <= 127 then
  begin
    Result := fDecodingTable[Ord(C) and $7F];
    If Result = Byte(-1) then
      raise EBTEProcessingError.CreateFmt('TBTEDecoder.ResolveChar: Unknown character (#%d).',[Ord(C)]);
  end
else raise EBTEProcessingError.CreateFmt('TBTEDecoder.ResolveChar: Invalid character (#%d).',[Ord(C)]);
end;

//------------------------------------------------------------------------------

Function TBTEDecoder.CountPadding: TStrSize;
var
  i:  TStrOff;
begin
Result := 0;
For i := Length(fEncodedString) downto 1 do
  If fEncodedString[i] = fPaddingChar then
    Inc(Result)
  else
    Break{For i};
end;

//------------------------------------------------------------------------------

procedure TBTEDecoder.Decode(const Buffer; Size: TMemSize);
begin
fBreakProcessing := False;
fIsProcessing := True;
try
  // read header
  ReadHeader;
  If fHeader then
    fEncodedStringPos := Succ(HeaderLength)
  else
    fEncodedStringPos := 1;
  DoProgress(0.0);
  // decoding-specific processing
  DecodeSpecific(Buffer,Size);
  DoProgress(1.0);
finally
  fIsProcessing := False;
end;
end;

{-------------------------------------------------------------------------------
    TBTEDecoder - public methods
-------------------------------------------------------------------------------}

procedure TBTEDecoder.ConstructDecodingTable(const EncodingTable: TBTEEncodingTable);
var
  i:  Integer;
begin
If EncodingTableIsValid(EncodingTable) then
  begin
    FillChar(fDecodingTable,SizeOf(TBTEDecodingTable),Byte(-1));
    For i := Low(EncodingTable) to High(EncodingTable) do
      fDecodingTable[Ord(EncodingTable[i]) and $7F] := i;
  end
else raise EBTEInvalidValue.Create('TBTEDecoder.ConstructDecodingTable: Invalid encoding table.');
end;

//------------------------------------------------------------------------------

Function TBTEDecoder.DecodeIntoBuffer(const Buffer; Size: TMemSize): TMemSize;
begin
Result := DecodedSize;
If Size >= Result then
  Decode(Buffer,Result)
else
  raise EBTEBufferTooSmall.CreateFmt('TBTEDecoder.DecodeIntoBuffer: Buffer too small (%u/%u).',[Size,Result]);
end;

//------------------------------------------------------------------------------

Function TBTEDecoder.DecodeIntoMemory(Mem: Pointer; Size: TMemSize): TMemSize;
begin
Result := DecodedSize;
If Size >= Result then
  Decode(Mem^,Result)
else
  raise EBTEBufferTooSmall.CreateFmt('TBTEDecoder.DecodeIntoMemory: Buffer too small (%u/%u).',[Size,Result]);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Function TBTEDecoder.DecodeIntoMemory(out Mem: Pointer): TMemSize; 
begin
Result := DecodedSize;
If Result > 0 then
  begin
    GetMem(Mem,Result);
    try
      Decode(Mem^,Result);
    except
      FreeMem(Mem,Result);
      Mem := nil;      
      Result := 0;
    end;
  end
else Mem := nil;
end;

//------------------------------------------------------------------------------

Function TBTEDecoder.DecodeIntoStream(Stream: TStream): TMemSize;
var
  Buffer: Pointer;
begin
Result := DecodeIntoMemory(Buffer);
try
  Stream.WriteBuffer(Buffer^,Result);
finally
  FreeMem(Buffer,Result);
end;
end;

//------------------------------------------------------------------------------

Function TBTEDecoder.DecodeIntoFile(const FileName: String): TMemSize;
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmCreate or fmShareDenyWrite);
try
  Result := DecodeIntoStream(FileStream);
finally
  FileStream.Free;
end;
end;


{===============================================================================
--------------------------------------------------------------------------------
                                 TBase2Encoder
--------------------------------------------------------------------------------
===============================================================================}
const
  EncodingTable_Base2: array[0..1] of Char = ('0','1');

{===============================================================================
    TBase2Encoder - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TBase2Encoder - protected methods
-------------------------------------------------------------------------------}

procedure TBase2Encoder.InitializeTable;
begin
AssignEncodingTable(EncodingTable_Base2);
end;

//------------------------------------------------------------------------------

procedure TBase2Encoder.EncodeSpecific(const Buffer; Size: TMemSize);
var
  DataPtr:  Pointer;
  i,j:      Integer;
  Temp:     Byte;
begin
DataPtr := ResolveDataPointer(@Buffer,Size,fReversed);
For i := 1 to Size do
  begin
    Temp := PByte(DataPtr)^;
    For j := 7 downto 0 do
      WriteChar(fEncodingTable[(Temp shr j) and 1]);
    If fBreakProcessing then
      Break{For i};
    AdvanceDataPointer(DataPtr,fReversed);
  end;
end;

{-------------------------------------------------------------------------------
    TBase2Encoder - public methods
-------------------------------------------------------------------------------}

class Function TBase2Encoder.DataLimit: TMemSize;
begin
Result := 64 * 1024 * 1024; // 64MiB
end;

//------------------------------------------------------------------------------

class Function TBase2Encoder.Encoding: TBTEEncoding;
begin
Result := encBase2;
end;

//------------------------------------------------------------------------------

class Function TBase2Encoder.EncodingFeatures: TBTEEncodingFeatures;
begin
Result := [efReversible,efOutputSize];
end;

//------------------------------------------------------------------------------

class Function TBase2Encoder.EncodingTableLength: Integer;
begin
Result := Length(EncodingTable_Base2);
end;

//------------------------------------------------------------------------------

Function TBase2Encoder.EncodedLengthFromBuffer(const Buffer; Size: TMemSize): TStrSize;
begin
If Size <= DataLimit then
  begin
    If fHeader then
      Result := TStrSize(Size * 8) + HeaderLength
    else
      Result := TStrSize(Size * 8);
  end
else raise EBTETooMuchData.CreateFmt('TBase2Encoder.EncodedLengthFromBuffer: Too much data (%u bytes).',[Size]);
end;


{===============================================================================
--------------------------------------------------------------------------------
                                 TBase2Decoder
--------------------------------------------------------------------------------
===============================================================================}
const
  DecodingTable_Base2: TBTEDecodingTable =
    ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $00, $01, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);

{===============================================================================
    TBase2Decoder - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TBase2Decoder - protected methods
-------------------------------------------------------------------------------}

procedure TBase2Decoder.InitializeTable;
begin
fDecodingTable := DecodingTable_Base2;
end;

//------------------------------------------------------------------------------

procedure TBase2Decoder.DecodeSpecific(const Buffer; Size: TMemSize);
var
  DataPtr:  Pointer;
  i,j:      Integer;
  Temp:     Byte;
begin
DataPtr := ResolveDataPointer(@Buffer,Size,fReversed);
For i := 1 to Size do
  begin
    Temp := 0;
    For j := 1 to 8 do
      Temp := (Temp shl 1) or ResolveChar(ReadChar);
    If fBreakProcessing then
      Break{For i};
    PByte(DataPtr)^ := Temp;
    AdvanceDataPointer(DataPtr,fReversed);
  end;
end;

{-------------------------------------------------------------------------------
    TBase2Decoder - public methods
-------------------------------------------------------------------------------}

class Function TBase2Decoder.DataLimit: TMemSize;
begin
Result := 64 * 1024 * 1024; // 64MiB
end;

//------------------------------------------------------------------------------

class Function TBase2Decoder.Encoding: TBTEEncoding;
begin
Result := encBase2;
end;

//------------------------------------------------------------------------------

class Function TBase2Decoder.EncodingFeatures: TBTEEncodingFeatures;
begin
Result := [efReversible,efOutputSize];
end;

//------------------------------------------------------------------------------

class Function TBase2Decoder.EncodingTableLength: Integer;
begin
Result := Length(EncodingTable_Base2);
end;

//------------------------------------------------------------------------------

Function TBase2Decoder.DecodedSize: TMemSize;
begin
If HeaderPresent(fEncodedString) then
  Result := TMemSize((Length(fEncodedString) - HeaderLength) div 8)
else
  Result := TMemSize(Length(fEncodedString) div 8)
end;


{===============================================================================
--------------------------------------------------------------------------------
                                 TBase64Encoder
--------------------------------------------------------------------------------
===============================================================================}
const
  EncodingTable_Base64: array[0..63] of Char =
    ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
     'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
     'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
     'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/');

  PaddingChar_Base64: Char = '=';

{===============================================================================
    TBase64Encoder - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TBase64Encoder - protected methods
-------------------------------------------------------------------------------}

procedure TBase64Encoder.InitializeTable;
begin
AssignEncodingTable(EncodingTable_Base64);
fPaddingChar := PaddingChar_Base64;
end;

//------------------------------------------------------------------------------

procedure TBase64Encoder.EncodeSpecific(const Buffer; Size: TMemSize);
var
  DataPtr:        Pointer;
  i:              Integer;
  Temp:           Byte;
  Remainder:      Byte;
  RemainderBits:  Integer;
begin
DataPtr := ResolveDataPointer(@Buffer,Size,fReversed);
Remainder := 0;
RemainderBits := 0;
For i := 1 to Size do
  begin
    Temp := PByte(DataPtr)^;
    case RemainderBits of
      0:  begin
            WriteChar(fEncodingTable[(Temp shr 2) and $3F]);
            Remainder := Temp and $03;
            RemainderBits := 2;
          end;
      2:  begin
            WriteChar(fEncodingTable[(Remainder shl 4) or ((Temp shr 4) and $F)]);
            Remainder := Temp and $0F;
            RemainderBits := 4;
          end;
      4:  begin
            WriteChar(fEncodingTable[(Remainder shl 2) or ((Temp shr 6) and $3)]);
            WriteChar(fEncodingTable[Temp and $3F]);
            Remainder := 0;
            RemainderBits := 0;
          end;
    else
      raise EBTEProcessingError.CreateFmt('TBase64Encoder.EncodeSpecific: Invalid RemainderBits (%d).',[RemainderBits]);
    end;
    If fBreakProcessing then
      Break{For i};
    AdvanceDataPointer(DataPtr,fReversed);
  end;
If not fBreakProcessing then
  begin
    // process possible remainder bits
    case RemainderBits of
      0:  ; // no remainder, do nothing
      2:  WriteChar(fEncodingTable[Remainder shl 4]);
      4:  WriteChar(fEncodingTable[Remainder shl 2]);
    else
      raise EBTEProcessingError.CreateFmt('TBase64Encoder.EncodeSpecific: Invalid RemainderBits (%d).',[RemainderBits]);
    end;
    // fill rest of the string with padding
    If fPadding then
      WritePadding;
  end;
end;

{-------------------------------------------------------------------------------
    TBase64Encoder - public methods
-------------------------------------------------------------------------------}

class Function TBase64Encoder.DataLimit: TMemSize;
begin
Result := 384 * 1024 * 1024;  // 384MiB
end;

//------------------------------------------------------------------------------

class Function TBase64Encoder.Encoding: TBTEEncoding;
begin
Result := encBase64;
end;

//------------------------------------------------------------------------------

class Function TBase64Encoder.EncodingFeatures: TBTEEncodingFeatures;
begin
Result := [efPadding,efReversible,efOutputSize];
end;

//------------------------------------------------------------------------------

class Function TBase64Encoder.EncodingTableLength: Integer;
begin
Result := Length(EncodingTable_Base64);
end;

//------------------------------------------------------------------------------

Function TBase64Encoder.EncodedLengthFromBuffer(const Buffer; Size: TMemSize): TStrSize;
begin
If Size <= DataLimit then
  begin
    If fPadding then
      Result := TStrSize(Ceil(Size / 3) * 4)
    else
      Result := TStrSize(Ceil((Size * 4) / 3));
    If fHeader then
      Result := Result + HeaderLength;
  end
else raise EBTETooMuchData.CreateFmt('TBase64Encoder.EncodedLengthFromBuffer: Too much data (%u bytes).',[Size]);
end;


{===============================================================================
--------------------------------------------------------------------------------
                                 TBase64Decoder
--------------------------------------------------------------------------------
===============================================================================}
const
  DecodingTable_Base64: TBTEDecodingTable =
    ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $3E, $FF, $FF, $FF, $3F,
     $34, $35, $36, $37, $38, $39, $3A, $3B, $3C, $3D, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E,
     $0F, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $FF, $FF, $FF, $FF, $FF,
     $FF, $1A, $1B, $1C, $1D, $1E, $1F, $20, $21, $22, $23, $24, $25, $26, $27, $28,
     $29, $2A, $2B, $2C, $2D, $2E, $2F, $30, $31, $32, $33, $FF, $FF, $FF, $FF, $FF);
     
{===============================================================================
    TBase64Decoder - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TBase64Decoder - protected methods
-------------------------------------------------------------------------------}

procedure TBase64Decoder.InitializeTable;
begin
fDecodingTable := DecodingTable_Base64;
fPaddingChar := PaddingChar_Base64;
end;

//------------------------------------------------------------------------------

procedure TBase64Decoder.DecodeSpecific(const Buffer; Size: TMemSize);
var
  DataPtr:        Pointer;
  i:              Integer;
  Temp:           Byte;
  Remainder:      Byte;
  RemainderBits:  Integer;
begin
DataPtr := ResolveDataPointer(@Buffer,Size,fReversed);
Remainder := 0;
RemainderBits := 0;
For i := 1 to Size do
  begin
    case RemainderBits of
      0:  begin
            Temp := ResolveChar(ReadChar) shl 2;
            Remainder := ResolveChar(ReadChar);
            Temp := Temp or ((Remainder shr 4) and 3);
            Remainder := Remainder and $F;
            RemainderBits := 4;
          end;
      2:  begin
            Temp := (Remainder shl 6) or ResolveChar(ReadChar);
            Remainder := 0;
            RemainderBits := 0;
          end;
      4:  begin
            Temp := Remainder shl 4;
            Remainder := ResolveChar(ReadChar);
            Temp := Temp or ((Remainder shr 2) and $F);
            Remainder := Remainder and 3;
            RemainderBits := 2;
          end;
    else
      raise EBTEProcessingError.CreateFmt('TBase64Decoder.DecodeSpecific: Invalid RemainderBits (%d).',[RemainderBits]);
    end;
    If fBreakProcessing then
      Break{For i};
    PByte(DataPtr)^ := Temp;
    AdvanceDataPointer(DataPtr,fReversed);
  end;
end;

{-------------------------------------------------------------------------------
    TBase64Decoder - public methods
-------------------------------------------------------------------------------}

class Function TBase64Decoder.DataLimit: TMemSize;
begin
Result := 384 * 1024 * 1024;  // 384MiB
end;

//------------------------------------------------------------------------------

class Function TBase64Decoder.Encoding: TBTEEncoding;
begin
Result := encBase64;
end;

//------------------------------------------------------------------------------

class Function TBase64Decoder.EncodingFeatures: TBTEEncodingFeatures;
begin
Result := [efPadding,efReversible,efOutputSize];
end;

//------------------------------------------------------------------------------

class Function TBase64Decoder.EncodingTableLength: Integer;
begin
Result := Length(EncodingTable_Base64);
end;

//------------------------------------------------------------------------------

Function TBase64Decoder.DecodedSize: TMemSize;
var
  PaddingCount: TStrSize;
begin
PaddingCount := CountPadding;
If HeaderPresent(fEncodedString) then
  Result := Floor(((Length(fEncodedString) - HeaderLength - PaddingCount) * 3) / 4)
else
  Result := Floor(((Length(fEncodedString) - PaddingCount) * 3) / 4);
fPadding := PaddingCount > 0;   
end;


end.
