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

interface

implementation

end.
