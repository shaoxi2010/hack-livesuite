function Tools_Utils()
  local retTbl = {}
  
  local readonly = function(t)
    local proxy = {}
    local mt = {
      __index = t,
      __newindex = function(t, k, v)
        error("Err, Attempt to update readonly table.")
      end
    }
    setmetatable(proxy, mt)
    return proxy
  end
  local getLine = function(level)
    return debug.getinfo(level, "l").currentline
  end
  local getFile = function(level)
    return debug.getinfo(level, "S").short_src
  end
  local DbgFmtPrint = function(fmt, ...)
    dbgMsg = string.format(fmt, ...)
    DebugTrace(dbgMsg)
  end
  local DbgFmtPrintL = function(fmt, ...)
    dbgMsg = string.format(fmt, ...)
    dbgMsg = dbgMsg .. "\r\n"
    DebugTrace(dbgMsg)
  end
  
  local function Mod_DbgFmtPrint(modPreFix, fmt, ...)
    DbgFmtPrint(modPreFix .. fmt, ...)
  end
  
  local Mod_DbgFmtPrintL = function(modPreFix, fmt, ...)
    dbgMsg = string.format(modPreFix .. fmt, ...)
    dbgMsg = dbgMsg .. "\r\n"
    DebugTrace(dbgMsg)
  end
  
  local function Mod_ErrPrintL(modPreFix, fmt, ...)
    return DbgFmtPrintL(modPreFix .. "%s_%d>:" .. fmt, getFile(4), getLine(4), ...)
  end
  
  retTbl.readonly = readonly
  retTbl.getLine = getLine
  retTbl.getFile = getFile
  retTbl.DbgFmtPrint = DbgFmtPrint
  retTbl.Mod_DbgFmtPrint = Mod_DbgFmtPrint
  retTbl.Mod_DbgFmtPrintL = Mod_DbgFmtPrintL
  retTbl.Mod_ErrPrintL = Mod_ErrPrintL
  return retTbl
end

local U = Tools_Utils()
local readonly = U.readonly

function Tools_Cfg()
  local readonly = U.readonly
  local SUB_TYPE_FES = {
    fes1_1 = "FES_1-0000000000"
  }
  local SUB_TYPE_USR_FS = {}
  local SUB_TYPE_COMMON = {
    sys_config = "SYS_CONFIG_BIN00",
    dtb = "DTB_CONFIG000000",
    split = "SPLIT_0000000000",
    sys_partition = "SYS_PARTITION000"
  }
  local SUB_TYPE_BOOT = {
    NAND_BOOT0 = "BOOT0_0000000000"
  }
  local SUB_TYPE_TOOLS = {
    usbtool = "xxxxxxxxxxxxxxxx"
  }
  local SUB_TYPE_MP_FILE = {
    boot0_nand = "BOOT0_0000000000",
    boot0_sdcard = "1234567890BOOT_0",
    boot0_spinor = "1234567890BNOR_0",
    uboot = "UBOOT_0000000000",
    toc0 = "TOC0_00000000000",
    toc1 = "TOC1_00000000000",
    card_tool = "1234567890cardtl",
    card_script = "1234567890script",
    sunxi_mbr = "1234567890___MBR",
    dlinfo = "1234567890DLINFO",
    full_image = "FULLIMG_00000000",
    boot_package = "BOOTPKG-00000000",
    boot_package_nor = "BOOTPKG-NOR00000"
  }
  local SUB_TYPE = {
    FES = readonly(SUB_TYPE_FES),
    USR_FS = readonly(SUB_TYPE_USR_FS),
    COMMON = readonly(SUB_TYPE_COMMON),
    BOOT = readonly(SUB_TYPE_BOOT),
    TOOLS = readonly(SUB_TYPE_TOOLS),
    MP_FILE = readonly(SUB_TYPE_MP_FILE)
  }
  local MAIN_TYPE = {
    COMMON = "COMMON  ",
    INFO = "INFO    ",
    BOOTROM = "BOOTROM ",
    FES = "FES     ",
    FET = "FET     ",
    FED = "FED     ",
    FEX = "FEX     ",
    BOOT = "BOOT    ",
    USR_FS = "RFSFAT16",
    TOOLS = "UPFLYTLS",
    MP_FILE = "12345678"
  }
  local _ITEM_NAME = {
    main = readonly(MAIN_TYPE),
    sub = readonly(SUB_TYPE)
  }
  local _Tools_Cfg = {
    IMG_BUF_LEN = 6291456,
    SYS_CFG_BUF_LEN = 65536,
    FEX_DOWN_LEN = 65536,
    MBR_COPY_NUM = 4
  }
  local _Boot_Package_Mode = {
    SUNXI_BOOT_FILE_NORMAL = 0,
    SUNXI_BOOT_FILE_TOC = 1,
    SUNXI_BOOT_FILE_RES0 = 2,
    SUNXI_BOOT_FILE_RES1 = 3,
    SUNXI_BOOT_FILE_PKG = 4
  }
  return readonly({
    ITEM_NAME = readonly(_ITEM_NAME),
    Tools_CFG = readonly(_Tools_Cfg),
    Boot_Package_Mode = readonly(_Boot_Package_Mode)
  })
end

local Cfg = Tools_Cfg()
local IMG_ITEM = Cfg.ITEM_NAME
SPARSE_INFO = {
  sparse_magic = 3978755898,
  sparse_major_ver = 1,
  sparse_header_size = 28,
  sparse_total_head = 65280,
  sparse_chunk_head = 65281,
  sparse_chunk_data = 65282,
  sparse_fill_data = 65283,
  chunk_header_size = 12,
  chunk_type_raw = 51905,
  chunk_type_fill = 51906,
  chunk_type_null = 51907
}

function Tools_File(fileName, mode)
  local function MsgPrintL(fmt, ...)
    U.Mod_DbgFmtPrintL("[TL_File]Msg:", fmt, ...)
  end
  
  local function ErrPrintL(fmt, ...)
    U.Mod_ErrPrintL("<TL_File>Err:", fmt, ...)
  end
  
  if not fopen then
    ErrPrintL("func fopen is nil")
    return nil
  end
  if not fclose then
    ErrPrintL("func fclose is nil")
    return nil
  end
  if not fwrite then
    ErrPrintL("func fwrite is nil")
    return nil
  end
  if not fread then
    ErrPrintL("func fread is nil")
    return nil
  end
  if not fseek then
    ErrPrintL("func fseek is nil")
    return nil
  end
  if not fgetALine then
    ErrPrintL("func fgetALine is nil")
    return nil
  end
  if "string" ~= type(fileName) or "string" ~= type(mode) then
    ErrPrintL("fileName=%s, mode=%s", type(fileName), type(mode))
    return nil
  end
  local hFile = fopen(fileName, mode)
  if 0 == hFile then
    ErrPrintL("Fail to open file %s, mode=%s", fileName, mode)
    return nil
  end
  
  local function Close()
    return fclose(hFile)
  end
  
  local function Read(pBuf, nLen)
    return fread(hFile, pBuf, nLen)
  end
  
  local function Write(pBuf, nLen)
    local wrLen = fwrite(hFile, pBuf, nLen)
    if wrLen ~= nLen then
      ErrPrintL("Want to write %dB, but %dB", nLen, wrLen)
      return false
    end
    return true
  end
  
  local function Seek(nPos, nFlag)
    return fseek(hFile, nPos, nFlag)
  end
  
  local function GetALine()
    return fgetALine(hFile)
  end
  
  return readonly({
    Close = Close,
    Read = Read,
    Write = Write,
    Seek = Seek,
    GetALine = GetALine
  })
end

function Tools_Buffer(nBufSz)
  local function MsgPrintL(fmt, ...)
    U.Mod_DbgFmtPrintL("[TL_BUF]:", fmt, ...)
  end
  
  local function ErrPrintL(fmt, ...)
    U.Mod_ErrPrintL("<TL_BUF>Err", fmt, ...)
  end
  
  if not MallocBuffer then
    ErrPrintL("func MallocBuffer     is nil")
    return nil
  end
  if not FreeBuffer then
    ErrPrintL("func FreeBuffer     is nil")
    return nil
  end
  if not GetBuffer then
    ErrPrintL("func GetBuffer      is nil")
    return nil
  end
  if not Memcpy then
    ErrPrintL("func Memcpy         is nil")
    return nil
  end
  if not Memset then
    ErrPrintL("func Memset         is nil")
    return nil
  end
  if not Memcmp then
    ErrPrintL("func Memcmp         is nil")
    return nil
  end
  if not BufferToString then
    ErrPrintL("func BufferToString is nil")
    return nil
  end
  if not StringtoBuffer then
    ErrPrintL("func StringtoBuffer is nil")
    return nil
  end
  if not GetMemValue then
    ErrPrintL("func GetMemValue    is nil")
    return nil
  end
  if not SetMemValue then
    ErrPrintL("func SetMemValue    is nil")
    return nil
  end
  if not BufferToChars then
    ErrPrintL("func BufferToChars  is nil")
    return nil
  end
  if not CharsToBuffer then
    ErrPrintL("func CharsToBuffer  is nil")
    return nil
  end
  if not GetInt32FrmMem then
    ErrPrintL("func GetInt32FrmMem is nil")
    return nil
  end
  if not SetInt32FrmMem then
    ErrPrintL("func SetInt32FrmMem is nil")
    return nil
  end
  if not GetInt16FrmMem then
    ErrPrintL("func GetInt16FrmMem is nil")
    return nil
  end
  if not SetInt16FrmMem then
    ErrPrintL("func SetInt16FrmMem is nil")
    return nil
  end
  if not GetByteBitsFrmMem then
    ErrPrintL("func GetByteBitsFrmMem is nil")
    return nil
  end
  if not SetByteBitsFrmMem then
    ErrPrintL("func SetByteBitsFrmMem is nil")
    return nil
  end
  if not GetIntBitsFrmMem then
    ErrPrintL("func GetIntBitsFrmMem is nil")
    return nil
  end
  if not SetIntBitsFrmMem then
    ErrPrintL("func SetIntBitsFrmMem is nil")
    return nil
  end
  if not GetInt8FrmMem then
    ErrPrintL("func GetInt8FrmMem is nil")
    return nil
  end
  if not SetInt8FrmMem then
    ErrPrintL("func SetInt8FrmMem is nil")
    return nil
  end
  if not CharsToBuffer then
    ErrPrintL("func CharsToBuffer is nil")
    return nil
  end
  if not BufferToChars then
    ErrPrintL("func BufferToChars is nil")
    return nil
  end
  if not calc_crc32 then
    ErrPrintL("func calc_crc32 is nil")
    return nil
  end
  if not add_sum then
    ErrPrintL("func add_sum is nil")
    return nil
  end
  if nBufSz <= 0 then
    ErrPrintL("@nBufSz(%d)<=0", nBufSz)
    return nil
  end
  local pBuffer = MallocBuffer(nBufSz)
  if not pBuffer then
    ErrPrintL("Fail to Alloc buffer, nBufSz=%d", nBufSz)
    return nil
  end
  Memset(pBuffer, 0, nBufSz)
  
  local function Free()
    FreeBuffer(pBuffer)
    pBuffer = nil
  end
  
  local function BuffShift(nOffset)
    if not pBuffer then
      ErrPrintL("pBuffer is nil, may be released yet!")
      return nil
    end
    return GetBuffer(pBuffer, nOffset)
  end
  
  local function MemCopy(para)
    if not pBuffer then
      ErrPrintL("pBuffer is nil, may be released yet!")
      return nil
    end
    if "table" ~= type(para) then
      ErrPrintL("para must be table")
      return nil
    end
    local srcBuf, srcOffset, nBytes, pos = para.srcBuf, para.srcOffset, para.nBytes, para.pos
    if not srcBuf or not srcBuf.GetPoint() then
      ErrPrintL("srcBuf or srcBuf.GetPoint() is nil")
      return nil
    end
    pos = pos or 0
    srcOffset = srcOffset or 0
    if pos + nBytes > nBufSz then
      ErrPrintL("copy @pos(%d) + @nBytes(%d)> nBufSz(%d) in dest buffer", pos, nBytes, nBufSz)
      return nil
    end
    local pp = BuffShift(pos)
    Memcpy(pp, srcBuf.BuffShift(srcOffset), nBytes)
    return true
  end
  
  local function MemSet(para)
    if "table" ~= type(para) then
      ErrPrintL("para must be table")
      return nil
    end
    local val, nBytes, pos = para.val, para.nBytes, para.pos
    if not pBuffer then
      ErrPrintL("pBuffer is nil, may be released yet!")
      return nil
    end
    pos = pos or 0
    if pos + nBytes > nBufSz then
      ErrPrintL("@pos(%d) + @nBytes(%d)>nBufSz(%d)", pos, nBytes, nBufSz)
      return nil
    end
    local pp = BuffShift(pos)
    Memset(pp, val, nBytes)
    return true
  end
  
  local function Zero()
    return MemSet({val = 0, nBytes = nBufSz})
  end
  
  local function MemCompare(para)
    if "table" ~= type(para) then
      ErrPrintL("para must be table")
      return nil
    end
    local anotherBuf, nBytes = para.anotherBuf, para.nBytes
    if not pBuffer then
      ErrPrintL("pBuffer is nil, may be released yet!")
      return nil
    end
    if not anotherBuf or not anotherBuf.GetPoint() then
      ErrPrintL("anotherBuf or anotherBuf.GetPoint() is nil")
      return nil
    end
    if nBytes > nBufSz then
      ErrPrintL("copy len @nBytes(%d)> nBufSz(%d) in dest buffer", nBytes, nBufSz)
      return nil
    end
    return Memcmp(pBuffer, anotherBuf.GetPoint(), nBytes)
  end
  
  local function GetMemVal2Int32(nOffset)
    if not pBuffer then
      ErrPrintL("pBuffer is nil, may be released yet!")
      return nil
    end
    nOffset = nOffset or 0
    if nOffset >= nBufSz then
      ErrPrintL("nOffset(%d) > nBufSz(%d)", nOffset, nBufSz)
      return false
    end
    return GetInt32FrmMem(pBuffer, nOffset)
  end
  
  local function SetMemValWithInt32(para)
    if not pBuffer then
      ErrPrintL("pBuffer is nil, may be released yet!")
      return nil
    end
    if "table" ~= type(para) then
      ErrPrintL("para must be table")
      return nil
    end
    local val, nOffset = para.val, para.nOffset
    nOffset = nOffset or 0
    if nOffset >= nBufSz then
      ErrPrintL("nOffset(%d) > nBufSz(%d)", nOffset, nBufSz)
      return false
    end
    SetInt32FrmMem(pBuffer, nOffset, val)
    return true
  end
  
  local function GetMemVal2Int16(nOffset)
    if not pBuffer then
      ErrPrintL("pBuffer is nil, may be released yet!")
      return nil
    end
    nOffset = nOffset or 0
    if nOffset >= nBufSz then
      ErrPrintL("nOffset(%d) > nBufSz(%d)", nOffset, nBufSz)
      return false
    end
    return GetInt16FrmMem(pBuffer, nOffset)
  end
  
  local function SetMemValWithInt16(para)
    if not pBuffer then
      ErrPrintL("pBuffer is nil, may be released yet!")
      return nil
    end
    if "table" ~= type(para) then
      ErrPrintL("para must be table")
      return nil
    end
    local val, nOffset = para.val, para.nOffset
    nOffset = nOffset or 0
    if nOffset >= nBufSz then
      ErrPrintL("nOffset(%d) > nBufSz(%d)", nOffset, nBufSz)
      return false
    end
    SetInt16FrmMem(pBuffer, nOffset, val)
    return true
  end
  
  local function GetMemVal2Int8(nOffset)
    if not pBuffer then
      ErrPrintL("pBuffer is nil, may be released yet!")
      return nil
    end
    nOffset = nOffset or 0
    if nOffset >= nBufSz then
      ErrPrintL("nOffset(%d) > nBufSz(%d)", nOffset, nBufSz)
      return false
    end
    return GetInt8FrmMem(pBuffer, nOffset)
  end
  
  local function SetMemValWithInt8(para)
    if not pBuffer then
      ErrPrintL("pBuffer is nil, may be released yet!")
      return nil
    end
    if "table" ~= type(para) then
      ErrPrintL("para must be table")
      return nil
    end
    local val, nOffset = para.val, para.nOffset
    nOffset = nOffset or 0
    if nOffset >= nBufSz then
      ErrPrintL("nOffset(%d) > nBufSz(%d)", nOffset, nBufSz)
      return false
    end
    SetInt8FrmMem(pBuffer, nOffset, val)
    return true
  end
  
  local function SetMemValWithChars(para)
    if not pBuffer then
      ErrPrintL("pBuffer is nil")
      return nil
    end
    local pos, str = para.pos, para.str
    if "string" ~= type(str) then
      ErrPrintL("para error, %s", type(str))
      return false
    end
    pos = pos or 0
    local pp = BuffShift(pos)
    CharsToBuffer(pp, str)
    return true
  end
  
  local function GetMemVal2Chars(para)
    if not pBuffer then
      ErrPrintL("pBuffer is nil")
      return nil
    end
    local pos, nLen = para.pos, para.nLen
    if not nLen then
      ErrPrintL("para nLen nil")
      return false
    end
    pos = pos or 0
    local str = BufferToChars(pBuffer, pos, nLen)
    return str
  end
  
  local function SetMemWithString(para)
    if not pBuffer then
      ErrPrintL("pBuffer is nil, may be released yet!")
      return nil
    end
    if "table" ~= type(para) then
      ErrPrintL("para not table, please check")
      return false
    end
    if not para.str or "string" ~= type(para.str) then
      ErrPrintL("para error, please check")
      return false
    end
    if not para.size or "number" ~= type(para.size) then
      ErrPrintL("para error, please check")
      return false
    end
    para.pos = para.pos or 0
    local pp = BuffShift(para.pos)
    CharsToBuffer(pp, para.str)
    return true
  end
  
  local function GetByteBits(para)
    if not pBuffer then
      ErrPrintL("pBuffer is nil, may be released yet!")
      return nil
    end
    if "table" ~= type(para) then
      ErrPrintL("para must be table")
      return nil
    end
    local nBytesOfst, nBitsOfst, nBits = para.nBytesOfst, para.nBitsOfst, para.nBits
    if nBytesOfst >= nBufSz then
      ErrPrintL("nOffset(%d) > nBufSz(%d)", nBytesOfst, nBufSz)
      return false
    end
    if 7 < nBitsOfst then
      ErrPrintL("Bit Ofst should be 0~7, but %d", nBitsOfst)
      return false
    end
    if 8 < nBitsOfst + nBits then
      ErrPrintL("BitsOfst(%d) + nBits(%d) > 8", nBitsOfst, nBits)
      return false
    end
    return GetByteBitsFrmMem(pBuffer, nBytesOfst, nBitsOfst, nBits)
  end
  
  local function SetByteBits(para)
    if not pBuffer then
      ErrPrintL("pBuffer is nil, may be released yet!")
      return nil
    end
    if "table" ~= type(para) then
      ErrPrintL("para must be table")
      return nil
    end
    local nBytesOfst, nBitsOfst, nBits, val = para.nBytesOfst, para.nBitsOfst, para.nBits, para.val
    if nBytesOfst >= nBufSz then
      ErrPrintL("nOffset(%d) > nBufSz(%d)", nBytesOfst, nBufSz)
      return false
    end
    if 7 < nBitsOfst then
      ErrPrintL("Bit Ofst should be 0~7, but %d", nBitsOfst)
      return false
    end
    if 8 < nBitsOfst + nBits then
      ErrPrintL("BitsOfst(%d) + nBits(%d) > 8", nBitsOfst, nBits)
      return false
    end
    SetByteBitsFrmMem(pBuffer, nBytesOfst, nBitsOfst, nBits, val)
    return true
  end
  
  local function GetIntBits(para)
    if not pBuffer then
      ErrPrintL("pBuffer is nil, may be released yet!")
      return nil
    end
    if "table" ~= type(para) then
      ErrPrintL("para must be table")
      return nil
    end
    local nBytesOfst, nBitsOfst, nBits = para.nBytesOfst, para.nBitsOfst, para.nBits
    if nBytesOfst + 4 >= nBufSz then
      ErrPrintL("nOffset(%d) > nBufSz(%d)", nBytesOfst, nBufSz)
      return false
    end
    if 31 < nBitsOfst then
      ErrPrintL("Bit Ofst should be 0~7, but %d", nBitsOfst)
      return false
    end
    if 32 < nBitsOfst + nBits then
      ErrPrintL("BitsOfst(%d) + nBits(%d) > 8", nBitsOfst, nBits)
      return false
    end
    return GetIntBitsFrmMem(pBuffer, nBytesOfst, nBitsOfst, nBits)
  end
  
  local function SetIntBits(para)
    if not pBuffer then
      ErrPrintL("pBuffer is nil, may be released yet!")
      return nil
    end
    if "table" ~= type(para) then
      ErrPrintL("para must be table")
      return nil
    end
    local nBytesOfst, nBitsOfst, nBits, val = para.nBytesOfst, para.nBitsOfst, para.nBits, para.val
    if nBytesOfst + 4 >= nBufSz then
      ErrPrintL("nOffset(%d) > nBufSz(%d)", nBytesOfst, nBufSz)
      return false
    end
    if 31 < nBitsOfst then
      ErrPrintL("Bit Ofst should be 0~7, but %d", nBitsOfst)
      return false
    end
    if 32 < nBitsOfst + nBits then
      ErrPrintL("BitsOfst(%d) + nBits(%d) > 8", nBitsOfst, nBits)
      return false
    end
    SetIntBitsFrmMem(pBuffer, nBytesOfst, nBitsOfst, nBits, val)
    return true
  end
  
  local function CalCrc32(para)
    local pos, nBytes = para.pos, para.nBytes
    if not nBytes then
      ErrPrintL("para error, nBytes nil")
      return false
    end
    pos = pos or 0
    if pos + nBytes > nBufSz then
      ErrPrintL("pos(%d) + nBytes(%d) > nBufSz(%d)", pos, nBytes, nBufSz)
      return false
    end
    local pp = BuffShift(pos)
    return calc_crc32(pp, nBytes)
  end
  
  local function AddSum(para)
    if "table" ~= type(para) then
      ErrPrintL("para error, type(%s)", type(para))
      return false
    end
    local pos, nBytes, org = para.pos, para.nBytes, para.org
    if not nBytes then
      ErrPrintL("nBytes nil")
      return nil
    end
    pos = pos or 0
    org = org or 0
    local pp = BuffShift(pos)
    local addSum = add_sum(pp, nBytes, org)
    return addSum
  end
  
  return readonly({
    Free = Free,
    MemCopy = MemCopy,
    MemSet = MemSet,
    Zero = Zero,
    MemCompare = MemCompare,
    GetMemVal2Int32 = GetMemVal2Int32,
    SetMemValWithInt32 = SetMemValWithInt32,
    GetMemVal2Int16 = GetMemVal2Int16,
    SetMemValWithInt16 = SetMemValWithInt16,
    GetMemVal2Int8 = GetMemVal2Int8,
    SetMemValWithInt8 = SetMemValWithInt8,
    BuffShift = BuffShift,
    SetMemWithString = SetMemWithString,
    SetByteBits = SetByteBits,
    GetByteBits = GetByteBits,
    SetIntBits = SetIntBits,
    GetIntBits = GetIntBits,
    GetMemVal2Chars = GetMemVal2Chars,
    SetMemValWithChars = SetMemValWithChars,
    CalCrc32 = CalCrc32,
    AddSum = AddSum,
    GetPoint = function()
      return pBuffer
    end,
    GetSize = function()
      return nBufSz
    end
  })
end

function Tools_Img(szImgFile)
  local function MsgPrintL(fmt, ...)
    U.Mod_DbgFmtPrintL("[TL_IMG]:", fmt, ...)
  end
  
  local function ErrPrintL(fmt, ...)
    U.Mod_ErrPrintL("<TL_IMG>Err:", fmt, ...)
  end
  
  if not Img_Open then
    ErrPrintL("func Img_Open is NULL\n")
    return nil
  end
  if not Img_Close then
    ErrPrintL("func Img_Close is NULL\n")
    return nil
  end
  if not Img_OpenItem then
    ErrPrintL("func Img_OpenItem is NULL\n")
    return nil
  end
  if not Img_CloseItem then
    ErrPrintL("func Img_CloseItem is NULL\n")
    return nil
  end
  if not Img_ReadItemData then
    ErrPrintL("func Img_ReadItemData is NULL\n")
    return nil
  end
  if not Img_GetItemSize then
    ErrPrintL("func Img_GetItemSize is NULL\n")
    return nil
  end
  local hImage = Img_Open(szImgFile)
  if not hImage then
    ErrPrintL("Fail to open image %s", szImgFile)
    return nil
  end
  
  local function CloseImg()
    return Img_Close(hImage)
  end
  
  local function Item(szMainType, szSubType)
    local function open_item(szMainType, szSubType)
      if "string" ~= type(szMainType) or "string" ~= type(szSubType) then
        ErrPrintL("item(%s, %s) all should be string", type(szMainType), type(szSubType))
        
        return false
      end
      return Img_OpenItem(hImage, szMainType, szSubType)
    end
    
    hItem = open_item(szMainType, szSubType)
    if not hItem then
      ErrPrintL("Fail to open Item<%s, %s>", szMainType, szSubType)
      return nil
    end
    
    local function close_item()
      ret = Img_CloseItem(hImage, hItem)
      return 0 == ret and true or false
    end
    
    local function read_item_data(pBuf, wantLen)
      readLen = Img_ReadItemData(hImage, hItem, pBuf, wantLen)
      ret = readLen == wantLen and true or false
      if not ret then
        ErrPrintL("want to read %dB, but %dB.\n", wantLen, readLen)
      end
      return ret
    end
    
    local itemSize = Img_GetItemSize(hImage, hItem)
    itemSize = not itemSize and 0 or itemSize
    
    local function get_item_sz()
      return itemSize
    end
    
    return {
      Close = close_item,
      Read = read_item_data,
      ItemSize = get_item_sz
    }
  end
  
  local function save_item_as_file(main_type, sub_type, filePath)
    if "string" ~= type(main_type) or "string" ~= type(sub_type) or "string" ~= type(filePath) then
      ErrPrintL("item(%s, %s) and filePath(%s) all should be string", type(main_type), type(sub_type), type(filePath))
      return false
    end
    local theItem = Item(main_type, sub_type)
    if not theItem then
      ErrPrintL("Fail to new a item.")
      return nil
    end
    local tl_File = Tools_File(filePath, "wb+")
    if not tl_File then
      ErrPrintL("Fail to open temporary file %s for item<%s, %s>", filePath, main_type, sub_type)
      theItem.Close()
      return false
    end
    local itemSz = theItem.ItemSize()
    local BufLen = math.min(Cfg.Tools_CFG.IMG_BUF_LEN, itemSz)
    local tl_Buf = Tools_Buffer(BufLen)
    if not tl_Buf then
      ErrPrintL("Fail to create buf. for item<%s,%s>", main_type, sub_type)
      tl_File.Close()
      theItem.Close()
      return false
    end
    local readTotalLen = 0
    repeat
      local wantLen = math.min(itemSz - readTotalLen, BufLen)
      local ppBuf = tl_Buf.BuffShift(readTotalLen)
      if not theItem.Read(ppBuf, wantLen) then
        ErrPrintL("fail to read item data")
        break
      end
      if not tl_File.Write(ppBuf, wantLen) then
        ErrPrintL("Failed to write to file.")
        break
      end
      readTotalLen = readTotalLen + wantLen
    until itemSz <= readTotalLen
    tl_Buf.Free()
    tl_File.Close()
    theItem.Close()
    return itemSz
  end
  
  local function save_item_to_mem(main_type, sub_type, tl_Buf)
    if "string" ~= type(main_type) or "string" ~= type(sub_type) then
      ErrPrintL("item(%s, %s) should be string", type(main_type), type(sub_type))
      return false
    end
    theItem = Item(main_type, sub_type)
    if not theItem then
      ErrPrintL("Fail to new a item.")
      return nil
    end
    local itemSz = theItem.ItemSize()
    if itemSz <= 0 then
      ErrPrintL("Fail to get item size")
      return false
    end
    if itemSz > tl_Buf.GetSize() then
      ErrPrintL("save_item_to_mem, itemSz(%d)>BufLen(%d)", theItem.ItemSize, tl_Buf.GetSize())
      theItem.Close()
      return false
    end
    local readTotalLen = 0
    repeat
      local leftLen = itemSz - readTotalLen
      local wantLen = math.min(leftLen, Cfg.Tools_CFG.FEX_DOWN_LEN)
      if not theItem.Read(tl_Buf.BuffShift(readTotalLen), wantLen) then
        ErrPrintL("fail to read item data")
        break
      end
      readTotalLen = readTotalLen + wantLen
    until itemSz <= readTotalLen
    theItem.Close()
    return itemSz
  end
  
  return readonly({
    CloseImg = CloseImg,
    Item = Item,
    save_item_as_file = save_item_as_file,
    save_item_to_mem = save_item_to_mem
  })
end

local FES_MEDIA_INDEX = readonly({
  DRAM = 0,
  FLASH_PHY = 1,
  FLASH_LOG = 2
})
local FEX_COMMAND_ID = readonly({
  VERIFY_DEV = 1,
  SWITCH_ROLE = 2,
  IS_READY = 3,
  GET_CMD_SET_VER = 4,
  DISCONNECT = 16,
  FEL_DOWN = 257,
  FEL_RUN = 258,
  FEL_UP = 259,
  FES_RUN = 514,
  FES_INFO = 515,
  FES_GET_MSG = 516,
  FES_UNREG_FED = 517,
  FEX_CMD_FES_DOWN = 518,
  FEX_CMD_FES_UP = 519,
  FEX_CMD_FES_VERIFY = 520,
  FEX_CMD_FES_QUERY_STORAGE = 521,
  FEX_CMD_FES_FLASH_SET_ON = 522,
  FEX_CMD_FES_FLASH_SET_OFF = 523,
  FEX_CMD_FES_VERIFY_VALUE = 524,
  FEX_CMD_FES_VERIFY_STATUS = 525,
  FEX_CMD_FES_FLASH_SIZE_PROBE = 526,
  FEX_CMD_FES_TOOL_MODE = 527,
  FEX_CMD_FES_QUERY_PKMODE = 560
})
local SUNXI_EFEX_TAG = readonly({
  sunxi_efex_data_type_mask = 32767,
  sunxi_efex_dram_mask = 32512,
  sunxi_efex_dram_tag = 32512,
  sunxi_efex_mbr_tag = 32513,
  sunxi_efex_uboot_tag = 32514,
  sunxi_efex_boot0_tag = 32515,
  sunxi_efex_erase_tag = 32516,
  sunxi_efex_flash_tag = 32768,
  sunxi_efex_trans_finish_tag = 65536,
  sunxi_efex_full_size_tag = 32528
})
local FES_DOU = readonly({DOWN = 1, UP = 2})

function Tools_Fex_Dev(szFexDevName)
  local function MsgPrintL(fmt, ...)
    U.Mod_DbgFmtPrintL("[TL_FEX]:", fmt, ...)
  end
  
  local function ErrPrintL(fmt, ...)
    U.Mod_ErrPrintL("<TL_FEX>Err", fmt, ...)
  end
  
  if not Fex_Open then
    ErrPrintL("func Fex_Open is NULL\n")
    return nil
  end
  if not Fex_Close then
    ErrPrintL("func Fex_Close is NULL\n")
    return nil
  end
  if not Fex_Query then
    ErrPrintL("func Fex_Query is NULL\n")
    return nil
  end
  if not Fex_Send then
    ErrPrintL("func Fex_Send is NULL\n")
    return nil
  end
  if not Fex_Recv then
    ErrPrintL("func Fex_Recv is NULL\n")
    return nil
  end
  if not Fex_command then
    ErrPrintL("func Fex_command is NULL\n")
    return nil
  end
  if not Fex_transmit_receive then
    ErrPrintL("func Fex_transmit_receive is NULL\n")
    return nil
  end
  local m_hFexDev = Fex_Open(szFexDevName)
  if not m_hFexDev then
    ErrPrintL("Fail to open fex dev")
    return nil
  end
  
  local function Close()
    Fex_Close(m_hFexDev)
    if m_tlBufCmd then
      m_tlBufCmd.Free()
    end
    m_hFexDev, m_tlBufCmd = nil, nil
    return true
  end
  
  local CMD_BUF_LEN = 16
  local m_tlBufCmd = Tools_Buffer(CMD_BUF_LEN)
  if not m_tlBufCmd then
    ErrPrintL("Fail to alloc buffer for fexCmd")
    Close()
    return nil
  end
  
  local function GenFexCmd_FelTrans(tlBufCmd, cmdPara)
    local addr, len = cmdPara.addr, cmdPara.len
    if "number" ~= type(addr) or "number" ~= type(len) then
      ErrPrintL("number ~= %s , number~= %s", type(addr), type(len))
      return nil
    end
    local ret = tlBufCmd.SetMemValWithInt32({val = addr, nOffset = 4})
    if not ret then
      ErrPrintL("Fail to set address.")
      return nil
    end
    ret = tlBufCmd.SetMemValWithInt32({val = len, nOffset = 8})
    if not ret then
      ErrPrintL("Fail to set len.")
      return nil
    end
    ret = tlBufCmd.SetMemValWithInt16({
      val = cmdPara.cmdId
    })
    return ret
  end
  
  local function GenFexCmd_FelRun(tlBufCmd, cmdPara)
    local addr = cmdPara.addr
    if "number" ~= type(addr) then
      ErrPrintL("number ~= %s ", type(addr))
      return nil
    end
    local ret = tlBufCmd.SetMemValWithInt32({val = addr, nOffset = 4})
    if not ret then
      ErrPrintL("Fail to set address.")
      return nil
    end
    ret = tlBufCmd.SetMemValWithInt16({
      val = FEX_COMMAND_ID.FEL_RUN
    })
    return ret
  end
  
  local function GenFexCmd_FesTrans(tlBufCmd, cmdPara)
    local addr, len, data_tag = cmdPara.addr, cmdPara.len, cmdPara.data_tag
    if "number" ~= type(addr) or "number" ~= type(len) then
      ErrPrintL("should(number, number), but(%s,%s)", type(addr), type(len))
      return nil
    end
    local ret = tlBufCmd.SetMemValWithInt16({val = 0, nOffset = 2})
    ret = tlBufCmd.SetMemValWithInt32({val = addr, nOffset = 4})
    if not ret then
      ErrPrintL("Fail to set address")
      return nil
    end
    ret = tlBufCmd.SetMemValWithInt32({val = len, nOffset = 8})
    if not ret then
      ErrPrintL("Fail to set len")
      return nil
    end
    ret = tlBufCmd.SetMemValWithInt32({val = data_tag, nOffset = 12})
    if not ret then
      ErrPrintL("Fail to set fes trans type")
      return nil
    end
    ret = tlBufCmd.SetMemValWithInt16({
      val = cmdPara.cmdId
    })
    return ret
  end
  
  local function GenFexCmd_FesRun(tlBufCmd, cmdPara)
    if "table" ~= type(tlBufCmd) or "table" ~= type(cmdPara) then
      ErrPrintL("type error")
      return nil
    end
    local codeAddr, hasPara, runType = cmdPara.codeAddr, cmdPara.hasPara, cmdPara.runType
    if not (codeAddr and hasPara) or not runType then
      ErrPrintL("type nil, %s, %s,%s", type(codeAddr), type(hasPara), type(runType))
      return nil
    end
    local ret = tlBufCmd.SetMemValWithInt32({val = codeAddr, nOffset = 4})
    if not ret then
      ErrPrintL("Fail to set address")
      return nil
    end
    local temp = runType * 16
    if hasPara then
      temp = temp + 1
    end
    ret = tlBufCmd.SetMemValWithInt8({val = temp, nOffset = 8})
    if not ret then
      ErrPrintL("set type error")
      return false
    end
    ret = tlBufCmd.SetMemValWithInt16({
      val = FEX_COMMAND_ID.FES_RUN
    })
    return ret
  end
  
  local function GenFexCmd_FesInfo(tlBufCmd, cmdPara)
    if "table" ~= type(tlBufCmd) or "table" ~= type(cmdPara) then
      ErrPrintL("type error")
      return nil
    end
    local ret = false
    ret = tlBufCmd.SetMemValWithInt16({
      val = FEX_COMMAND_ID.FES_INFO
    })
    return ret
  end
  
  local function GenFexCmd_FesGetMsg(tlBufCmd, cmdPara)
    if "table" ~= type(tlBufCmd) or "table" ~= type(cmdPara) then
      ErrPrintL("type error")
      return nil
    end
    local ret = false
    local msg_len = 1024
    ret = tlBufCmd.SetMemValWithInt32({val = msg_len, nOffset = 4})
    if not ret then
      ErrPrintL("fail to set msg_len")
      return false
    end
    ret = tlBufCmd.SetMemValWithInt16({
      val = FEX_COMMAND_ID.FES_GET_MSG
    })
    return ret
  end
  
  local function GenFexCmd_FesVerifyDev(tlBufCmd, cmdPara)
    if "table" ~= type(tlBufCmd) or "table" ~= type(cmdPara) then
      ErrPrintL("type error")
      return nil
    end
    local ret = false
    ret = tlBufCmd.SetMemValWithInt16({
      val = FEX_COMMAND_ID.VERIFY_DEV
    })
    return ret
  end
  
  local function GenFexCmd_unRegFed(tlBufCmd, cmdPara)
    if "table" ~= type(tlBufCmd) or "table" ~= type(cmdPara) then
      ErrPrintL("type error")
      return nil
    end
    local ret, media_index = false, cmdPara.media_index
    ret = tlBufCmd.SetMemValWithInt16({val = media_index, nOffset = 4})
    ret = tlBufCmd.SetMemValWithInt16({
      val = FEX_COMMAND_ID.FES_UNREG_FED
    })
    return ret
  end
  
  local function GenFexCmd_VerifyValue(tlBufCmd, cmdPara)
    if "table" ~= type(tlBufCmd) or "table" ~= type(cmdPara) then
      ErrPrintL("type error")
      return nil
    end
    local start, size = cmdPara.start, cmdPara.size
    local ret = tlBufCmd.SetMemValWithInt32({val = start, nOffset = 4})
    if not ret then
      ErrPrintL("fail to set verify start")
      return false
    end
    ret = tlBufCmd.SetMemValWithInt32({val = size, nOffset = 8})
    if not ret then
      ErrPrintL("fail to set verify size")
      return false
    end
    ret = tlBufCmd.SetMemValWithInt16({
      val = FEX_COMMAND_ID.FEX_CMD_FES_VERIFY_VALUE
    })
    MsgPrintL("%x, %x", start, size)
    return ret
  end
  
  local function GenFexCmd_VerifyStatus(tlBufCmd, cmdPara)
    if "table" ~= type(tlBufCmd) or "table" ~= type(cmdPara) then
      ErrPrintL("type error")
      return nil
    end
    local start, size, tag = cmdPara.start, cmdPara.size, cmdPara.tag
    local ret = tlBufCmd.SetMemValWithInt32({val = start, nOffset = 4})
    if not ret then
      ErrPrintL("fail to set verify status start")
      return false
    end
    ret = tlBufCmd.SetMemValWithInt32({val = size, nOffset = 8})
    if not ret then
      ErrPrintL("fail to set verify status  size")
      return false
    end
    ret = tlBufCmd.SetMemValWithInt32({val = tag, nOffset = 12})
    if not ret then
      ErrPrintL("fail to set verify status  tag")
      return false
    end
    ret = tlBufCmd.SetMemValWithInt16({
      val = FEX_COMMAND_ID.FEX_CMD_FES_VERIFY_STATUS
    })
    return ret
  end
  
  local function GenFexCmd_SetFlashOnOff(tlBufCmd, cmdPara)
    if "table" ~= type(tlBufCmd) or "table" ~= type(cmdPara) then
      ErrPrintL("type error")
      return nil
    end
    local flash_type = cmdPara.flash_type
    local ret = tlBufCmd.SetMemValWithInt32({val = flash_type, nOffset = 4})
    if not ret then
      ErrPrintL("fail to set flash_type")
      return false
    end
    ret = tlBufCmd.SetMemValWithInt16({
      val = cmdPara.cmdId
    })
    return ret
  end
  
  local function GenFexCmd_SetToolMode(tlBufCmd, cmdPara)
    if "table" ~= type(tlBufCmd) or "table" ~= type(cmdPara) then
      ErrPrintL("type error")
      return nil
    end
    local tool_mode, next_mode = cmdPara.tool_mode, cmdPara.next_mode
    local ret = tlBufCmd.SetMemValWithInt32({val = tool_mode, nOffset = 4})
    if not ret then
      ErrPrintL("fail to set tool mode")
      return false
    end
    local ret = tlBufCmd.SetMemValWithInt32({val = next_mode, nOffset = 8})
    if not ret then
      ErrPrintL("fail to set next mode")
      return false
    end
    ret = tlBufCmd.SetMemValWithInt16({
      val = FEX_COMMAND_ID.FEX_CMD_FES_TOOL_MODE
    })
    return ret
  end
  
  local function GenFexCmd_Normal(tlBufCmd, cmdPara)
    if "table" ~= type(tlBufCmd) or "table" ~= type(cmdPara) then
      ErrPrintL("type error")
      return nil
    end
    ret = tlBufCmd.SetMemValWithInt16({
      val = cmdPara.cmdId
    })
    return ret
  end
  
  local function GenFexCmdBuf(cmdPara)
    if "table" ~= type(cmdPara) then
      ErrPrintL("cmdPara should be table,but %s", type(cmdPara))
      return nil
    end
    if "number" ~= type(cmdPara.cmdId) then
      ErrPrintL("field cmdId shoud be number, but %s", type(cmdPara.cmdId))
      return nil
    end
    local cmdId = cmdPara.cmdId
    if not m_tlBufCmd then
      ErrPrintL("Fail to get buffer for fexCmd")
      return nil
    end
    m_tlBufCmd.Zero()
    local ret = true
    if FEX_COMMAND_ID.SWITCH_ROLE == cmdId then
    elseif FEX_COMMAND_ID.IS_READY == cmdId then
    elseif FEX_COMMAND_ID.GET_CMD_SET_VER == cmdId then
    elseif FEX_COMMAND_ID.DISCONNECT == cmdId then
    elseif FEX_COMMAND_ID.FEL_DOWN == cmdId then
      ret = GenFexCmd_FelTrans(m_tlBufCmd, cmdPara)
    elseif FEX_COMMAND_ID.FEL_RUN == cmdId then
      ret = GenFexCmd_FelRun(m_tlBufCmd, cmdPara)
    elseif FEX_COMMAND_ID.FEL_UP == cmdId then
      ret = GenFexCmd_FelTrans(m_tlBufCmd, cmdPara)
    elseif FEX_COMMAND_ID.FES_RUN == cmdId then
      ret = GenFexCmd_FesRun(m_tlBufCmd, cmdPara)
    elseif FEX_COMMAND_ID.FES_INFO == cmdId then
      ret = GenFexCmd_FesInfo(m_tlBufCmd, cmdPara)
    elseif FEX_COMMAND_ID.FES_GET_MSG == cmdId then
      ret = GenFexCmd_FesGetMsg(m_tlBufCmd, cmdPara)
    elseif FEX_COMMAND_ID.VERIFY_DEV == cmdId then
      ret = GenFexCmd_FesVerifyDev(m_tlBufCmd, cmdPara)
    elseif FEX_COMMAND_ID.FES_UNREG_FED == cmdId then
      MsgPrintL("GenCmd 0x%x, unreg fed", cmdId)
      ret = GenFexCmd_unRegFed(m_tlBufCmd, cmdPara)
    elseif FEX_COMMAND_ID.FEX_CMD_FES_DOWN == cmdId then
      ret = GenFexCmd_FesTrans(m_tlBufCmd, cmdPara)
    elseif FEX_COMMAND_ID.FEX_CMD_FES_UP == cmdId then
      ret = GenFexCmd_FesTrans(m_tlBufCmd, cmdPara)
    elseif FEX_COMMAND_ID.FEX_CMD_FES_VERIFY == cmdId then
      ret = GenFexCmd_Normal_(m_tlBufCmd, cmdPara)
    elseif FEX_COMMAND_ID.FEX_CMD_FES_QUERY_STORAGE == cmdId then
      ret = GenFexCmd_Normal(m_tlBufCmd, cmdPara)
    elseif FEX_COMMAND_ID.FEX_CMD_FES_FLASH_SET_ON == cmdId then
      ret = GenFexCmd_SetFlashOnOff(m_tlBufCmd, cmdPara)
    elseif FEX_COMMAND_ID.FEX_CMD_FES_FLASH_SET_OFF == cmdId then
      ret = GenFexCmd_SetFlashOnOff(m_tlBufCmd, cmdPara)
    elseif FEX_COMMAND_ID.FEX_CMD_FES_VERIFY_VALUE == cmdId then
      ret = GenFexCmd_VerifyValue(m_tlBufCmd, cmdPara)
    elseif FEX_COMMAND_ID.FEX_CMD_FES_VERIFY_STATUS == cmdId then
      ret = GenFexCmd_VerifyStatus(m_tlBufCmd, cmdPara)
    elseif FEX_COMMAND_ID.FEX_CMD_FES_FLASH_SIZE_PROBE == cmdId then
      ret = GenFexCmd_Normal(m_tlBufCmd, cmdPara)
    elseif FEX_COMMAND_ID.FEX_CMD_FES_TOOL_MODE == cmdId then
      ret = GenFexCmd_SetToolMode(m_tlBufCmd, cmdPara)
    elseif FEX_COMMAND_ID.FEX_CMD_FES_QUERY_PKMODE == cmdId then
      ret = GenFexCmd_Normal(m_tlBufCmd, cmdPara)
    else
      ErrPrintL("Unhandled fex cmd id[%d]", cmdId)
      ret = false
    end
    if not ret then
      ErrPrintL("Fail to gen fex command, id = %d", cmdId)
      return false
    end
    return ret
  end
  
  local function SendFexCommand(para)
    local tlBufData, dataSz, bufOffset = para.tlBufData, para.dataSz, para.bufOffset
    local tlBufCmd = m_tlBufCmd
    if "table" ~= type(tlBufCmd) then
      ErrPrintL("%s", type(tlBufCmd))
      return nil
    end
    if 16 ~= tlBufCmd.GetSize() then
      ErrPrintL("arg error in SendFexCommand, %d", tlBufCmd.GetSize())
      return nil
    end
    dataSz = dataSz or 0
    bufOffset = bufOffset or 0
    local bufCap = not tlBufData and 0 or tlBufData.GetSize()
    local pp = not tlBufData and 0 or tlBufData.BuffShift(bufOffset)
    if dataSz > bufCap - bufOffset then
      ErrPrintL("dataSz(0x%x) > bufCap(0x%x) - bufOffset(0x%x)", dataSz, bufCap, bufOffset)
      return false
    end
    local ret = Fex_command(m_hFexDev, tlBufCmd.GetPoint(), pp, dataSz)
    if 0 ~= ret then
      MsgPrintL("fexCdmRet = %d", ret)
    end
    tlBufCmd.Zero()
    return 0 == ret and true or false
  end
  
  local function FelDownData(para)
    if "table" ~= type(para) then
      ErrPrintL("para error, %s", type(para))
      return nil
    end
    local addr, len, dataBuf, bufOffset = para.addr, para.len, para.dataBuf, para.bufOffset
    if not (addr and len) or not dataBuf then
      ErrPrintL("para error, %s, %s, %s", type(addr), type(len), type(dataBuf))
      return nil
    end
    local _ret = false
    local thisDownLen, leftLen = 0, len
    repeat
      local FexLen = Cfg.Tools_CFG.FEX_DOWN_LEN
      local totalDownLen = len - leftLen
      thisDownLen = leftLen > FexLen and FexLen or leftLen
      _ret = GenFexCmdBuf({
        addr = addr + totalDownLen,
        len = thisDownLen,
        cmdId = FEX_COMMAND_ID.FEL_DOWN
      })
      if not _ret then
        ErrPrintL("Failed to gen fexCommand")
        _ret = false
        break
      end
      bufOffset = bufOffset or 0
      _ret = SendFexCommand({
        tlBufData = dataBuf,
        dataSz = thisDownLen,
        bufOffset = bufOffset + totalDownLen
      })
      if not ret then
        ErrPrintL("Failed to down data to fel.")
        break
      end
      leftLen = leftLen - thisDownLen
    until leftLen <= 0
    return _ret
  end
  
  local function FelClearArea(para)
    if "table" ~= type(para) then
      ErrPrintL("para error, table but %s", type(para))
      return nil
    end
    local addr, len = para.addr, para.len
    if not addr or not len then
      ErrPrintL("para error, %s, %s", type(addr), type(len))
      return nil
    end
    local bufZero = Tools_Buffer(len)
    if not bufZero then
      ErrPrintL("Fail to gen data buf")
      return nil
    end
    local ret = FelDownData({
      addr = addr,
      len = len,
      dataBuf = bufZero
    })
    bufZero.Free()
    return ret
  end
  
  local function FelUpData(para)
    if "table" ~= type(para) then
      ErrPrintL("para error, %s", type(para))
      return nil
    end
    local addr, len, dataBuf = para.addr, para.len, para.dataBuf
    if not (addr and len) or not dataBuf then
      ErrPrintL("para error, %s, %s, %s", type(addr), type(len), type(dataBuf))
      return nil
    end
    local ret = GenFexCmdBuf({
      addr = addr,
      len = len,
      cmdId = FEX_COMMAND_ID.FEL_UP
    })
    if not ret then
      ErrPrintL("Fail to gen buf for FelUpData")
      return nil
    end
    MsgPrintL("fel UP addr=0x%x, len=%d", addr, len)
    ret = SendFexCommand({tlBufData = dataBuf, dataSz = len})
    return ret
  end
  
  local function FelRun(para)
    if "table" ~= type(para) then
      ErrPrintL("para error, %s", type(para))
      return nil
    end
    local addr = para.addr
    if not addr then
      ErrPrintL("addr nil.")
      return nil
    end
    local ret = GenFexCmdBuf({
      addr = addr,
      cmdId = FEX_COMMAND_ID.FEL_RUN
    })
    if not ret then
      ErrPrintL("Fail to gen buf for FelRun")
      return nil
    end
    ret = SendFexCommand({})
    return ret
  end
  
  local function FesTransCmd(para)
    local tlBufData, dataSz, bufOffset = para.tlBufData, para.dataSz, para.bufOffset
    local tlBufCmd = m_tlBufCmd
    if "table" ~= type(tlBufCmd) then
      ErrPrintL("Fes cmd type: %s", type(tlBufCmd))
      return nil
    end
    if 16 ~= tlBufCmd.GetSize() then
      ErrPrintL("arg error in SendFexCommand, %d", tlBufCmd.GetSize())
      return nil
    end
    dataSz = dataSz or 0
    bufOffset = bufOffset or 0
    local bufCap = not tlBufData and 0 or tlBufData.GetSize()
    if dataSz > bufCap - bufOffset then
      ErrPrintL("dataSz(0x%x) > bufCap(0x%x) - bufOffset(0x%x)", dataSz, bufCap, bufOffset)
      return false
    end
    local ret
    local pp = tlBufCmd.GetPoint()
    local pData = not tlBufData and 0 or tlBufData.BuffShift(bufOffset)
    local TRANSFERDATA_DIRECTION_RECV, TRANSFERDATA_DIRECTION_SEND = 17, 18
    ret = Fex_transmit_receive(m_hFexDev, pp, 16, TRANSFERDATA_DIRECTION_SEND)
    if not ret then
      ErrPrintL("Fail to send fex cmd")
      return nil
    end
    local cmdId = m_tlBufCmd.GetMemVal2Int16(0)
    if FEX_COMMAND_ID.FEX_CMD_FES_DOWN == cmdId then
      ret = Fex_transmit_receive(m_hFexDev, pData, dataSz, TRANSFERDATA_DIRECTION_SEND)
      if not ret then
        ErrPrintL("Fail to send fex cmd")
        return nil
      end
    elseif FEX_COMMAND_ID.FEX_CMD_FES_UP == cmdId or FEX_COMMAND_ID.FEX_CMD_FES_VERIFY == cmdId or FEX_COMMAND_ID.FEX_CMD_FES_QUERY_STORAGE == cmdId or FEX_COMMAND_ID.FEX_CMD_FES_VERIFY_VALUE == cmdId or FEX_COMMAND_ID.FEX_CMD_FES_VERIFY_STATUS == cmdId or FEX_COMMAND_ID.FEX_CMD_FES_FLASH_SIZE_PROBE == cmdId or FEX_COMMAND_ID.FEX_CMD_FES_QUERY_PKMODE == cmdId then
      ret = Fex_transmit_receive(m_hFexDev, pData, dataSz, TRANSFERDATA_DIRECTION_RECV)
      if not ret then
        ErrPrintL("Fail to send fex cmd")
        return nil
      end
    elseif FEX_COMMAND_ID.FEX_CMD_FES_FLASH_SET_ON == cmdId or FEX_COMMAND_ID.FEX_CMD_FES_FLASH_SET_OFF == cmdId or FEX_COMMAND_ID.FEX_CMD_FES_TOOL_MODE == cmdId then
    else
      ErrPrintL("fes command invalid: cmdId = %x", cmdId)
    end
    ret = Fex_transmit_receive(m_hFexDev, pp, 8, TRANSFERDATA_DIRECTION_RECV)
    if not ret then
      ErrPrintL("fes cmd error: get cmd status ")
      return nil
    end
    if 0 ~= tlBufCmd.GetMemVal2Int8(4) then
      ErrPrintL("Fes cmd error: status error")
      return false
    end
    tlBufCmd.Zero()
    return 0 == ret and true or false
  end
  
  local function FesTransData(para)
    local addr, len, dataBuf, bufOffset, uiPromptOnce, uiCbProgress, totalUnPromptLenInPkt, uiCurrent, data_tag, media_index, DOU = para.addr, para.len, para.dataBuf, para.bufOffset, para.uiPromptOnce, para.uiCbProgress, para.totalUnPromptLenInPkt, para.uiCurrent, para.data_tag, para.media_index, para.DOU
    if not (addr and len and dataBuf) or not DOU then
      ErrPrintL("para nil:%s,%s,%s,%s", type(addr), type(len), type(dataBuf), type(DOU))
      return nil
    end
    bufOffset = bufOffset or 0
    local _ret
    local thisTransLen, leftLen = 0, len
    local tmpCmdId = para.DOU == FES_DOU.DOWN and FEX_COMMAND_ID.FEX_CMD_FES_DOWN or FEX_COMMAND_ID.FEX_CMD_FES_UP
    repeat
      local FexLen = Cfg.Tools_CFG.FEX_DOWN_LEN
      local totalTransLen = len - leftLen
      thisTransLen = leftLen > FexLen and FexLen or leftLen
      local thisDownAddr = FES_MEDIA_INDEX.DRAM == media_index and addr + totalTransLen or addr + totalTransLen / 512
      local tmp_tag = thisTransLen == leftLen and data_tag + SUNXI_EFEX_TAG.sunxi_efex_trans_finish_tag or data_tag
      _ret = GenFexCmdBuf({
        addr = thisDownAddr,
        len = thisTransLen,
        cmdId = tmpCmdId,
        data_tag = tmp_tag
      })
      if not _ret then
        ErrPrintL("Failed to gen fes command down.")
        _ret = false
        break
      end
      _ret = FesTransCmd({
        tlBufData = dataBuf,
        dataSz = thisTransLen,
        bufOffset = bufOffset + totalTransLen
      })
      if not _ret then
        ErrPrintL("Failed to trans data to FES.")
        break
      end
      if uiCbProgress then
        totalUnPromptLenInPkt = totalUnPromptLenInPkt + thisTransLen
        if uiPromptOnce <= totalUnPromptLenInPkt then
          local steps = totalUnPromptLenInPkt / uiPromptOnce
          steps = steps - steps % 1
          uiCurrent = uiCurrent + steps
          uiCbProgress({nPercents = uiCurrent})
          totalUnPromptLenInPkt = totalUnPromptLenInPkt - steps * uiPromptOnce
        end
      end
      leftLen = leftLen - thisTransLen
    until leftLen <= 0
    return _ret
  end
  
  local function FesDownData(para)
    para.DOU = FES_DOU.DOWN
    return FesTransData(para)
  end
  
  local function FesUpData(para)
    para.DOU = FES_DOU.UP
    return FesTransData(para)
  end
  
  local function FesRun(para)
    local codeAddr, runType, hasPara = para.codeAddr, para.runType, para.hasPara
    if not (codeAddr and runType) or not hasPara then
      ErrPrintL("type (%s,%s,%s)", type(codeAddr), type(runType), type(hasPara))
      return nil
    end
    para.cmdId = FEX_COMMAND_ID.FES_RUN
    local ret = GenFexCmdBuf(para)
    if not ret then
      ErrPrintL("failed to gen fex cmd buffer")
      return false
    end
    local dataBuf = Tools_Buffer(16)
    if not dataBuf then
      ErrPrintL("Fail to alloc buffer for para")
      return false
    end
    if hasPara then
      local para1Addr, para2Addr, para3Addr, para4Addr = para.para1Addr, para.para2Addr, para.para3Addr, para.para4Addr
      if para1Addr then
        ret = dataBuf.SetMemValWithInt32({val = para1Addr})
        if not ret then
          ErrPrintL("Fail to set para1")
          dataBuf.Free()
          return false
        end
      end
      if para2Addr then
        ret = dataBuf.SetMemValWithInt32({val = para2Addr, nOffset = 4})
        if not ret then
          ErrPrintL("Fail to set para2")
          dataBuf.Free()
          return false
        end
      end
      if para3Addr then
        ret = dataBuf.SetMemValWithInt32({val = para3Addr, nOffset = 8})
        if not ret then
          ErrPrintL("Fail to set para3")
          dataBuf.Free()
          return false
        end
      end
      if para4Addr then
        ret = dataBuf.SetMemValWithInt32({val = para4Addr, nOffset = 12})
        if not ret then
          ErrPrintL("Fail to set para4")
          dataBuf.Free()
          return false
        end
      end
    end
    MsgPrintL("fes run addr = 0x%x", codeAddr)
    ret = SendFexCommand({tlBufData = dataBuf, dataSz = 16})
    dataBuf.Free()
    return ret
  end
  
  local function FesInfo()
    local INFO_DATA_LEN = 32
    local infoData = Tools_Buffer(INFO_DATA_LEN)
    if not infoData then
      ErrPrintL("Fail to gen buffer for infodata")
      return nil
    end
    local ret
    repeat
      ret = GenFexCmdBuf({
        cmdId = FEX_COMMAND_ID.FES_INFO
      })
      if not ret then
        ErrPrintL("Fail to gen fex info cmd buf")
        return nil
      end
      ret = SendFexCommand({tlBufData = infoData, dataSz = INFO_DATA_LEN})
      if not ret then
        ErrPrintL("Fail to send fex command FES_INFO")
        infoData.Free()
        return nil
      end
      local busy = 1 == infoData.GetMemVal2Int8() and true or false
    until not busy
    local haveMsg = infoData.GetMemVal2Int8(1)
    infoData.Free()
    return ret, 1 == haveMsg
  end
  
  local function FesGetMsg(para)
    local msgBuf = para.msgBuf
    local MSG_BUF_LEN = 1024
    if "table" ~= type(msgBuf) or MSG_BUF_LEN > msgBuf.GetSize() then
      ErrPrintL("para error")
      return nil
    end
    msgBuf.Zero()
    local ret = GenFexCmdBuf({
      cmdId = FEX_COMMAND_ID.FES_GET_MSG
    })
    if not ret then
      ErrPrintL("fail to gen fex cmd get_msg")
      return nil
    end
    ret = SendFexCommand({tlBufData = msgBuf, dataSz = MSG_BUF_LEN})
    if not ret then
      ErrPrintL("Fail to send fex cmd get_msg")
      return nil
    end
    return ret
  end
  
  local function FesInfoAndGetMsgBody(para)
    local msgBuf, msgDataBuf = para.msgBuf, para.msgDataBuf
    if "table" ~= type(msgBuf) then
      ErrPrintL("type error(%s)", type(msgBuf))
      return nil
    end
    local ret, haveMsg = FesInfo()
    if not ret then
      ErrPrintL("fail to query fes info")
      return false
    end
    if not haveMsg then
      MsgPrintL("WRN, fes have no msg yet")
      return 0
    end
    ret = FesGetMsg(para)
    if not ret then
      ErrPrintL("Fail to get msg")
      return false
    end
    local dataLen = msgBuf.GetMemVal2Int16()
    if msgDataBuf then
      if dataLen > msgDataBuf.GetSize() then
        ErrPrintL("dataSz(0x%x)>dataBufSize(0x%x)", dataLen, msgDataBuf.GetSize())
        return false
      end
      ret = msgDataBuf.MemCopy({
        srcBuf = msgBuf,
        srcOffset = 24,
        nBytes = dataLen
      })
      if not ret then
        ErrPrintL("Fail to copy data.")
        return false
      end
    end
    return dataLen
  end
  
  local function FexVerifyDev(para)
    local dataBuf = para.dataBuf
    local DATA_BUF_LEN = 32
    if "table" ~= type(dataBuf) or DATA_BUF_LEN > dataBuf.GetSize() then
      ErrPrintL("para error, %s, %d", type(dataBuf), dataBuf.GetSize())
      return nil
    end
    local ret = GenFexCmdBuf({
      cmdId = FEX_COMMAND_ID.VERIFY_DEV
    })
    if not ret then
      ErrPrintL("fail to gen fex cmd verify device")
      return nil
    end
    ret = SendFexCommand({tlBufData = dataBuf, dataSz = DATA_BUF_LEN})
    if not ret then
      ErrPrintL("Fail to send fex cmd verify device")
      return nil
    end
    return ret
  end
  
  local function Fes_down_finish_flag(para)
    local dataBuf = Tools_Buffer(32)
    local ret = FexVerifyDev({dataBuf = dataBuf})
    if not ret then
      ErrPrintL("Fail to verify device")
      dataBuf.Free()
      return false
    end
    local pho_data_start_addr = dataBuf.GetMemVal2Int32(20)
    MsgPrintL("pho_data_start_addr is 0x%x", pho_data_start_addr)
    dataBuf.Zero()
    dataBuf.SetMemValWithInt16({val = 42445})
    dataBuf.SetMemValWithInt16({val = 4660})
    ret = FesDownData({
      addr = pho_data_start_addr + 4,
      len = 4,
      dataBuf = dataBuf
    })
    dataBuf.Free()
    return ret
  end
  
  local function Fes_unRegFed(para)
    local dataBuf, media_index = para.dataBuf, para.media_index
    if "table" ~= type(dataBuf) then
      ErrPrintL("para error, %s", type(dataBuf))
      return nil
    end
    local ret = GenFexCmdBuf({
      cmdId = FEX_COMMAND_ID.FES_UNREG_FED,
      media_index = media_index
    })
    if not ret then
      ErrPrintL("fail to gen fex cmd verify device")
      return nil
    end
    local pp = m_tlBufCmd.GetPoint()
    local TRANSFERDATA_DIRECTION_RECV, TRANSFERDATA_DIRECTION_SEND = 17, 18
    ret = Fex_transmit_receive(m_hFexDev, pp, 16, TRANSFERDATA_DIRECTION_SEND)
    if not ret then
      ErrPrintL("Fail to send fex cmd")
      return nil
    end
    ret = Fex_transmit_receive(m_hFexDev, pp, 8, TRANSFERDATA_DIRECTION_RECV)
    if not ret then
      ErrPrintL("Fail to get unReg fed result")
      return nil
    end
    if 0 ~= m_tlBufCmd.GetMemVal2Int8(4) then
      ErrPrintL("Fail to unReg Fed")
      return false
    end
    return ret
  end
  
  local function FexVerifyValue(para)
    local dataBuf, start, size = para.dataBuf, para.start, para.size
    local DATA_BUF_LEN = 12
    if "table" ~= type(dataBuf) or DATA_BUF_LEN > dataBuf.GetSize() then
      ErrPrintL("para error, %s, %d", type(dataBuf), dataBuf.GetSize())
      return nil
    end
    if "number" ~= type(start) or "number" ~= type(size) then
      ErrPrintL("para error, need number")
      return nil
    end
    local ret = GenFexCmdBuf({
      cmdId = FEX_COMMAND_ID.FEX_CMD_FES_VERIFY_VALUE,
      start = start,
      size = size
    })
    if not ret then
      ErrPrintL("fail to gen fex cmd verify value")
      return nil
    end
    ret = FesTransCmd({tlBufData = dataBuf, dataSz = DATA_BUF_LEN})
    if not ret then
      ErrPrintL("Fail to send fex cmd verify value")
      return nil
    end
    return ret
  end
  
  local function FexVerifyStatus(para)
    local dataBuf = para.dataBuf
    local DATA_BUF_LEN = 12
    if "table" ~= type(dataBuf) or DATA_BUF_LEN > dataBuf.GetSize() then
      ErrPrintL("para error, %s, %d", type(dataBuf), dataBuf.GetSize())
      return nil
    end
    local ret = GenFexCmdBuf({
      cmdId = FEX_COMMAND_ID.FEX_CMD_FES_VERIFY_STATUS,
      start = 0,
      size = 0,
      tag = para.tag
    })
    if not ret then
      ErrPrintL("fail to gen fex cmd verify status")
      return nil
    end
    ret = FesTransCmd({tlBufData = dataBuf, dataSz = DATA_BUF_LEN})
    if not ret then
      ErrPrintL("Fail to send fex cmd verify status")
      return nil
    end
    return ret
  end
  
  local function FexQueryStorage(para)
    local dataBuf = para.dataBuf
    local DATA_BUF_LEN = 4
    if "table" ~= type(dataBuf) or DATA_BUF_LEN > dataBuf.GetSize() then
      ErrPrintL("para error, %s, %d", type(dataBuf), dataBuf.GetSize())
      return nil
    end
    local ret = GenFexCmdBuf({
      cmdId = FEX_COMMAND_ID.FEX_CMD_FES_QUERY_STORAGE
    })
    if not ret then
      ErrPrintL("fail to gen fex cmd query storage")
      return nil
    end
    ret = FesTransCmd({tlBufData = dataBuf, dataSz = DATA_BUF_LEN})
    if not ret then
      ErrPrintL("Fail to send fex cmd query storage")
      return nil
    end
    return ret
  end
  
  local function FexProbeFlashSize(para)
    local dataBuf = para.dataBuf
    local DATA_BUF_LEN = 4
    if "table" ~= type(dataBuf) or DATA_BUF_LEN > dataBuf.GetSize() then
      ErrPrintL("para error, %s, %d", type(dataBuf), dataBuf.GetSize())
      return nil
    end
    local ret = GenFexCmdBuf({
      cmdId = FEX_COMMAND_ID.FEX_CMD_FES_FLASH_SIZE_PROBE
    })
    if not ret then
      ErrPrintL("fail to gen fex cmd probe flash size")
      return nil
    end
    ret = FesTransCmd({tlBufData = dataBuf, dataSz = DATA_BUF_LEN})
    if not ret then
      ErrPrintL("Fail to send fex cmd probe flash size")
      return nil
    end
    return ret
  end
  
  local function FexProbeBootPackageMode(para)
    local dataBuf = para.dataBuf
    local DATA_BUF_LEN = 4
    if "table" ~= type(dataBuf) or DATA_BUF_LEN > dataBuf.GetSize() then
      ErrPrintL("para error, %s, %d", type(dataBuf), dataBuf.GetSize())
      return nil
    end
    local ret = GenFexCmdBuf({
      cmdId = FEX_COMMAND_ID.FEX_CMD_FES_QUERY_PKMODE
    })
    if not ret then
      ErrPrintL("fail to gen fex cmd Probe BootPackage Mode")
      return nil
    end
    ret = FesTransCmd({tlBufData = dataBuf, dataSz = DATA_BUF_LEN})
    if not ret then
      ErrPrintL("Fail to send fex cmd Probe BootPackage Mode")
      return nil
    end
    return ret
  end
  
  local function FexSetFlashOnOff(para)
    if "table" ~= type(para) then
      ErrPrintL("para error, %s", type(para))
      return nil
    end
    local flash_on, flash_type = para.flash_on, para.flash_type
    local tmpCmdId, ret
    tmpCmdId = flash_on == 1 and FEX_COMMAND_ID.FEX_CMD_FES_FLASH_SET_ON or FEX_COMMAND_ID.FEX_CMD_FES_FLASH_SET_OFF
    ret = GenFexCmdBuf({cmdId = tmpCmdId, flash_type = flash_type})
    if not ret then
      ErrPrintL("fail to gen fex cmd set flash onoff")
      return nil
    end
    ret = FesTransCmd({tlBufData = dataBuf, dataSz = DATA_BUF_LEN})
    if not ret then
      ErrPrintL("Fail to send fex cmd flash OnOff")
      return nil
    end
    return ret
  end
  
  local function FexSetToolMode(para)
    if "table" ~= type(para) then
      ErrPrintL("para error, %s", type(para))
      return nil
    end
    local tool_mode, next_mode = para.tool_mode, para.next_mode
    local ret = GenFexCmdBuf({
      cmdId = FEX_COMMAND_ID.FEX_CMD_FES_TOOL_MODE,
      tool_mode = para.tool_mode,
      next_mode = para.next_mode
    })
    if not ret then
      ErrPrintL("fail to gen fex cmd set tool mode")
      return nil
    end
    ret = FesTransCmd({tlBufData = dataBuf, dataSz = DATA_BUF_LEN})
    if not ret then
      ErrPrintL("Fail to send fex cmd set tool mode")
      return nil
    end
    return ret
  end
  
  return readonly({
    FES_MEDIA_INDEX = FES_MEDIA_INDEX,
    FES_MEDIA_OOC = FES_MEDIA_OOC,
    FES_DOU = FES_DOU,
    FEX_COMMAND_ID = FEX_COMMAND_ID,
    Close = Close,
    FelDownData = FelDownData,
    FelClearArea = FelClearArea,
    FelUpData = FelUpData,
    FelRun = FelRun,
    FesDownData = FesDownData,
    FesUpData = FesUpData,
    FesRun = FesRun,
    FesInfo = FesInfo,
    FesGetMsg = FesGetMsg,
    FesInfoAndGetMsgBody = FesInfoAndGetMsgBody,
    Fes_down_finish_flag = Fes_down_finish_flag,
    Fes_unRegFed = Fes_unRegFed,
    Fex_VerifyDev = FexVerifyDev,
    Fex_VerifyValue = FexVerifyValue,
    Fex_VerifyStatus = FexVerifyStatus,
    Fex_QueryStorage = FexQueryStorage,
    Fex_ProbeFlashSize = FexProbeFlashSize,
    Fex_SetFlashOnOff = FexSetFlashOnOff,
    Fex_SetToolMode = FexSetToolMode,
    Fex_ProbeBootPackageMode = FexProbeBootPackageMode
  })
end

local function Tools_UI(para)
  local function MsgPrintL(fmt, ...)
    U.Mod_DbgFmtPrintL("[TL_UI]", fmt, ...)
  end
  
  local function ErrPrintL(fmt, ...)
    U.Mod_ErrPrintL("<TL_UI>Err", fmt, ...)
  end
  
  if not ToolMsgCallBack then
    ErrPrintL("func ToolMsgCallBack is not registered yet!")
    return nil
  end
  local ret, DevId, imgLen, downSpeed = nil, para.DevId, para.imgLen, para.downSpeed
  local TOOL_STEP = 16
  local TOOL_ERROR = 32
  local TOOL_WARN = 48
  local TOOL_OVER = 64
  local TOOL_TIP = 80
  local m_totalDownTime = 5
  if imgLen and downSpeed then
    m_totalDownTime = imgLen / downSpeed
  end
  
  local function SendProgress(para)
    local ret, nPercents = nil, para.nPercents
    if "number" ~= type(nPercents) then
      ErrPrintL("para error, (nPercents) %s", type(nPercents))
      return nil
    end
    local leftTime = m_totalDownTime * (100 - nPercents) / 100
    local leftMinutes = leftTime - leftTime % 1
    local leftSeconds = leftTime % 1 * 60
    leftSeconds = leftSeconds - leftSeconds % 1
    local szLeftTime = "Left (" .. leftMinutes .. ") Minutes and (" .. leftSeconds .. ") Seconds"
    ret = ToolMsgCallBack(DevId, TOOL_STEP, szLeftTime, nPercents)
    return 0 == ret and true or false
  end
  
  local function PromptError(para)
    local ret, errId, errMsg = nil, para.errId, para.errMsg
    if "number" ~= type(errId) or "string" ~= type(errMsg) then
      ErrPrintL("type error errId(%s), errMsg(%s)", type(errId), type(errMsg))
      return nil
    end
    ret = ToolMsgCallBack(DevId, TOOLS_ERROR, errMsg, errId)
    return 0 == ret and true or false
  end
  
  local function SendFesEnd(para)
    local ret = ToolMsgCallBack(DevId, TOOL_OVER, "", 0)
    return 0 == ret and true or false
  end
  
  return readonly({
    SendProgress = SendProgress,
    PromptError = PromptError,
    SendFesEnd = SendFesEnd
  })
end

local function fex_address_table(a)
  if a then
    return a
  end
  local a = {SYS_PARA_LOG = 1296126532, DRAM_UPDATED = 1}
  a.SYS_PARA_LOG_LEN = 16
  a.DRAM_INIT_CODE_LEN = 131072
  return readonly(a)
end

local FEX_MEM_MAP
module("Tools", package.seeall)

local function MsgPrintL(fmt, ...)
  U.Mod_DbgFmtPrintL("[TL_MSG]:", fmt, ...)
end

local function ErrPrintL(fmt, ...)
  U.Mod_ErrPrintL("<TL_ERR>:", fmt, ...)
end

local function PrintTbl(tbl_para)
  if "table" ~= type(tbl_para) then
    ErrPrintL("para error")
    return
  end
  for k, v in pairs(tbl_para) do
    print(k, v)
  end
end

local WORK_MODE_PRODUCT = 4
local WORK_MODE_UPDATE = 8
local toolsInitPara = {
  imgFilePath = "",
  workDir = "",
  Mode = WORK_MODE_UPDATE,
  hWnd = nil,
  ImgLenLow = 0,
  ImgLenHigh = 0,
  image = nil,
  erase_flag = 0
}

function Init(tbl_InitPara)
  print("--------------Init Called------------------")
  PrintTbl(tbl_InitPara)
  if "table" ~= type(tbl_InitPara) then
    ErrPrintL("type of arg of Init must be table")
  end
  if not tbl_InitPara.Mode then
    MsgPrintL("Mode nil")
    return false
  end
  if not tbl_InitPara.ImgLenHigh then
    MsgPrintL("ImgLenHigh nil")
    return false
  end
  if not tbl_InitPara.ImgLenLow then
    MsgPrintL("ImgLenLow nil")
    return false
  end
  MsgPrintL("Mode = %d, ImgLenHigh=%x, ImgLenLow = %x, imgFilePath = %s", tbl_InitPara.Mode, tbl_InitPara.ImgLenHigh, tbl_InitPara.ImgLenLow, tbl_InitPara.imgFilePath)
  if FEX_MEM_MAP then
    ErrPrint("FEX_MEM_MAP defined!!")
    return false
  end
  FEX_MEM_MAP = fex_address_table(FEX_MEM_MAP)
  local image = Tools_Img(tbl_InitPara.imgFilePath)
  if not image then
    ErrPrintL("Fail to creat Tools_Img")
    return false
  end
  MsgPrintL("Tools Open Img")
  local nMsgRet = ToolMessageBox("", "")
  if -1 == nMsgRet then
    ErrPrintL("User cancel to update")
    image.CloseImg()
    return false
  end
  tbl_InitPara.image = image
  tbl_InitPara.erase_flag = nMsgRet
  toolsInitPara = readonly(tbl_InitPara)
  print("---fun end---")
  return true
end

function Exit()
  print("---------------Exit Called-----------------")
  if toolsInitPara ~= nil then
    local image = toolsInitPara.image
    if image then
      image.CloseImg()
      MsgPrintL("Tools Close Img ...")
    end
    toolsInitPara = nil
  end
  print("---fun end---")
  return true
end

local function fel_down_item(para)
  local szMainType, szSubType, tlFelBuf, tlFelDev, codeAddr, codeMaxLen, image = para.szMainType, para.szSubType, para.tlFelBuf, para.tlFelDev, para.codeAddr, para.codeMaxLen, para.image
  if "string" ~= type(szMainType) or "string" ~= type(szSubType) or "table" ~= type(tlFelBuf) or not tlFelDev then
    ErrPrintL("arg check error, %s, %s, %s", type(szMainType), type(szSubType), type(tlFelBuf))
    return nil
  end
  local realLen = image.save_item_to_mem(szMainType, szSubType, tlFelBuf)
  if not realLen then
    ErrPrintL("Fail to save item to mem.")
    return false
  end
  if codeMaxLen < realLen then
    ErrPrintL("code len(%d) > maxLen(%d)", realLen, codeMaxLen)
    return false
  end
  local ret = tlFelDev.FelDownData({
    addr = codeAddr,
    len = realLen,
    dataBuf = tlFelBuf,
    bufOffset = 0
  })
  if not ret then
    ErrPrintL("Fail to down code")
    return false
  end
  return ret
end

local function fel_down_and_run_fes1(para)
  local szMainType, szSubType, tlFelBuf, tlFelDev, image = para.szMainType, para.szSubType, para.tlFelBuf, para.tlFelDev, para.image
  local realLen = image.save_item_to_mem(szMainType, szSubType, tlFelBuf)
  if not realLen then
    ErrPrintL("Fail to save item to mem.")
    return false
  end
  if realLen > FEX_MEM_MAP.DRAM_INIT_CODE_LEN then
    ErrPrintL("fes1 size too large: %d.", realLen)
    return false
  end
  local retAddr = tlFelBuf.GetMemVal2Int32(28)
  local codeAddr = tlFelBuf.GetMemVal2Int32(32)
  MsgPrintL("fes1 down addr = 0x%x, retAddr =0x%x", codeAddr, retAddr)
  local ret = tlFelDev.FelDownData({
    addr = codeAddr,
    len = realLen,
    dataBuf = tlFelBuf,
    bufOffset = 0
  })
  if not ret then
    ErrPrintL("Fail to down code fes1")
    return false
  end
  local logAreaAddr, logAreaLen = retAddr, FEX_MEM_MAP.SYS_PARA_LOG_LEN
  MsgPrintL("To clear fes aide log")
  local ret = tlFelDev.FelClearArea({addr = logAreaAddr, len = logAreaLen})
  if not ret then
    ErrPrintL("Fail to Clear fes aide log area")
    return false
  end
  ret = tlFelDev.FelRun({addr = codeAddr})
  if not ret then
    ErrPrintL("Fail to Run code fes1")
    return false
  end
  local hasRetLog = nil == para.hasRetLog and true or para.hasRetLog
  if not hasRetLog then
    MsgPrintL("not hasRetLog")
    return ret
  end
  local dramUpSize = 136
  local tlBufRetInfo = Tools_Buffer(dramUpSize)
  if not tlBufRetInfo then
    ErrPrintL("Fail to alloc buffer for fes_aide_info.")
    return false
  end
  for i = 1, 5 do
    ToolsSuspend(500)
    ret = tlFelDev.FelUpData({
      addr = logAreaAddr,
      len = dramUpSize,
      dataBuf = tlBufRetInfo
    })
    if not ret then
      ErrPrintL("FAil to UP fes aide log area, times=%d", i)
      tlBufRetInfo.Free()
      return false
    end
    local procEndFlag = tlBufRetInfo.GetMemVal2Int32()
    MsgPrintL("SYS_PARA_LOG read = 0x%x", procEndFlag)
    if FEX_MEM_MAP.SYS_PARA_LOG == procEndFlag then
      ret = tlBufRetInfo.GetMemVal2Int32(4)
      if ret == 1 then
        for j = 0, 31 do
          local drampara = tlBufRetInfo.GetMemVal2Int32(8 + j * 4)
          MsgPrintL("dram paras[%d]: 0x%x", j, drampara)
        end
      end
      break
    end
  end
  tlBufRetInfo.Free()
  return ret
end

local function fel_down_and_run_uboot(para)
  local szMainType, szSubType, tlFelBuf, tlFelDev, image = para.szMainType, para.szSubType, para.tlFelBuf, para.tlFelDev, para.image
  if "string" ~= type(szMainType) or "string" ~= type(szSubType) or "table" ~= type(tlFelBuf) or not tlFelDev then
    ErrPrintL("arg check error, %s, %s, %s", type(szMainType), type(szSubType), type(tlFelBuf))
    return nil
  end
  local realLen = image.save_item_to_mem(szMainType, szSubType, tlFelBuf)
  if not realLen then
    ErrPrintL("Fail to save item to mem.")
    return false
  end
  local codeAddr = tlFelBuf.GetMemVal2Int32(44)
  MsgPrintL("u-boot down addr = 0x%x", codeAddr)
  local set_workmode = tlFelBuf.SetMemValWithInt32({nOffset = 224, val = 16})
  if not set_workmode then
    ErrPrintL("fail to set work mode to 0x10")
    return false
  end
  MsgPrintL("workmode = 0x%x", tlFelBuf.GetMemVal2Int32(224))
  local ret = tlFelDev.FelDownData({
    addr = codeAddr,
    len = realLen,
    dataBuf = tlFelBuf,
    bufOffset = 0
  })
  if not ret then
    ErrPrintL("Fail to down code")
    return false
  end
  realLen = image.save_item_to_mem(IMG_ITEM.main.COMMON, IMG_ITEM.sub.COMMON.dtb, tlFelBuf)
  if not realLen then
    ErrPrintL("Fail to save  dtb item to mem.")
    return false
  end
  local dtbAddr = codeAddr + 2097152
  MsgPrintL("dtb down addr = 0x%x", dtbAddr)
  ret = tlFelDev.FelDownData({
    addr = dtbAddr,
    len = realLen,
    dataBuf = tlFelBuf,
    bufOffset = 0
  })
  if not ret then
    ErrPrintL("Fail to down dtb")
    return false
  end
  realLen = image.save_item_to_mem(IMG_ITEM.main.COMMON, IMG_ITEM.sub.COMMON.sys_config, tlFelBuf)
  if not realLen then
    ErrPrintL("Fail to save sys_config item to mem.")
    return false
  end
  local sysconfigAddr = dtbAddr + 1048576
  MsgPrintL("sysconfig down addr = 0x%x", sysconfigAddr)
  ret = tlFelDev.FelDownData({
    addr = sysconfigAddr,
    len = realLen,
    dataBuf = tlFelBuf,
    bufOffset = 0
  })
  if not ret then
    ErrPrintL("Fail to down sys_config")
    return false
  end
  ret = tlFelDev.FelRun({addr = codeAddr})
  if not ret then
    ErrPrintL("Fail to Run code")
    return false
  end
  return ret
end

local function fes_check_crc(para)
  local ret, verify_file, devId, tlFesDev, tlImg, tlBuf, pc_crc = nil, para.verify_file, para.devId, para.tlFesDev, para.tlImg, para.tlBuf, para.pc_crc
  if "number" ~= type(devId) or "table" ~= type(tlFesDev) or "table" ~= type(tlBuf) then
    ErrPrintL("type error, %s, %s, %s, %s, %s", type(devId), type(tlFesDev), type(tlBuf))
    return nil
  end
  if not pc_crc then
    if "string" ~= type(verify_file) then
      ErrPrintL("verify_file nil")
      return false
    end
    ret = tlImg.save_item_to_mem(IMG_ITEM.main.USR_FS, verify_file, tlBuf)
    if not ret then
      ErrPrintL("Failed to save verify file(%s) to mem.", verify_file)
      return false
    end
    pc_crc = tlBuf.GetMemVal2Int32()
  end
  ret = tlFesDev.FesUpData({
    addr = FEX_MEM_MAP.FEX_CRC32_VALID_ADDR,
    len = FEX_MEM_MAP.FEX_CRC32_VALID_LEN,
    dataBuf = tlBuf
  })
  if not ret then
    ErrPrintL("Fail to get crc from fes.")
    return false
  end
  if FEX_MEM_MAP.FEX_CRC32_VALID_FLAG ~= tlBuf.GetMemVal2Int32() then
    ErrPrintL("flag error")
    return false
  end
  local fes_crc, media_crc = tlBuf.GetMemVal2Int32(4), tlBuf.GetMemVal2Int32(8)
  MsgPrintL("id[%d]: pc_crc=0X%X, fes_crc = 0X%X, media_crc = 0X%X", devId, pc_crc, fes_crc, media_crc)
  if pc_crc ~= media_crc then
    ErrPrintL("CRC check ERRO, pc_crc ~= media_crc")
    return false
  end
  return ret
end

local function fes_down_normal_item(para)
  if "table" ~= type(para) then
    ErrPrintL("type should be table, but %s", type(para))
    return nil
  end
  local partNum, partName, mainType, subType, tlBufImg, tlFesDev, tlImg, addr, maxLen, bufOffset, uiStart, uiEnd, uiCbProgress, data_tag, media_index, mbr_part_key = para.partNum, para.partName, para.mainType, para.subType, para.tlBufImg, para.tlFesDev, para.tlImg, para.addr, para.maxLen, para.bufOffset, para.uiStepStart, para.uiStepEnd, para.uiCbProgress, para.data_tag, para.media_index, para.mbr_part_key
  if "string" ~= type(mainType) or "string" ~= type(subType) or "table" ~= type(tlBufImg) or "table" ~= type(tlFesDev) or "table" ~= type(tlImg) or "number" ~= type(addr) or "number" ~= type(maxLen) then
    ErrPrintL("type should string, string, table, table, table, number,number, but(%s, %s, %s, %s, %s, %s, %s)", type(mainType), type(subType), type(tlBufImg), type(tlFesDev), type(tlImg), type(addr), type(maxLen))
    return nil
  end
  local theItem = tlImg.Item(mainType, subType)
  if not theItem then
    ErrPrintL("Fail to open item")
    return false
  end
  local itemSz = theItem.ItemSize()
  if maxLen < itemSz then
    ErrPrintL("itemSz(0x%x)>maxLen(0x%x)", itemSz, maxLen)
    theItem.Close()
    return false
  end
  if partName == "UDISK" and WORK_MODE_UPDATE == toolsInitPara.Mode then
    MsgPrintL("work mode update ,udisk part for debug !!!!")
  end
  if partName == "UDISK" and itemSz <= 1024 then
    MsgPrintL("the data length of udisk is too small,ignore it!!!!")
    return true
  end
  if (partName == "private" or mbr_part_key[partName] == 32768) and WORK_MODE_UPDATE == toolsInitPara.Mode then
    MsgPrintL("work mode update ,  part %s ignore, keydata=%x !!!!", partName, mbr_part_key[partNum])
    return true
  end
  local totalUnPromptLenInPkt, uiCurrent = 0, uiStart
  local uiPromptOnce = 0
  if uiCbProgress then
    local uiPromptTimes = uiEnd + 1 - uiStart
    uiPromptOnce = itemSz / uiPromptTimes
  end
  bufOffset = bufOffset or 0
  local pp = tlBufImg.BuffShift(bufOffset)
  local totalReadLen, ret = 0, false
  local bufLen = tlBufImg.GetSize() - bufOffset
  repeat
    local leftLen = itemSz - totalReadLen
    local downAddr = FES_MEDIA_INDEX.DRAM == media_index and addr + totalReadLen or addr + totalReadLen / 512
    local wantLen = bufLen < leftLen and bufLen or leftLen
    ret = theItem.Read(pp, wantLen)
    if not ret then
      ErrPrintL("Fail to read item")
      break
    end
    ret = tlFesDev.FesDownData({
      addr = downAddr,
      len = wantLen,
      dataBuf = tlBufImg,
      bufOffset = bufOffset,
      uiPromptOnce = uiPromptOnce,
      uiCbProgress = uiCbProgress,
      totalUnPromptLenInPkt = totalUnPromptLenInPkt,
      uiCurrent = uiCurrent,
      data_tag = data_tag,
      media_index = media_index
    })
    if not ret then
      theItem.Close()
      ErrPrintL("Failed to down to FES")
      break
    end
    totalReadLen = totalReadLen + wantLen
    if uiCbProgress then
      local steps = totalReadLen / uiPromptOnce
      steps = steps - steps % 1
      uiCurrent = uiStart + steps
      totalUnPromptLenInPkt = totalReadLen - steps * uiPromptOnce
    end
  until itemSz <= totalReadLen
  theItem.Close()
  return ret
end

local handled_chunk = 0

local function parse_and_down_chunk(para)
  local tlFesDev, sparseBuf, sparseOfs, sparseLen, blk_size, retPara = para.tlFesDev, para.sparseBuf, para.sparseOfs, para.sparseLen, para.sparseBlkSize, para.retPara
  if "table" ~= type(tlFesDev) or "table" ~= type(sparseBuf) or "table" ~= type(retPara) or "number" ~= type(sparseOfs) or "number" ~= type(sparseLen) or "number" ~= type(blk_size) then
    ErrPrintL("para check error: (%s,%s,%s,%s,%s,%s)", type(tlFesDev), type(sparseBuf), type(retPara), type(sparseOfs), type(sparseLen), type(blk_size))
    return nil
  end
  local sparse_format_type = retPara.sparse_format_type
  local chunk_length = retPara.chunk_length
  local flash_start = retPara.flash_start
  local last_rest_size = retPara.last_rest_size
  sparseOfs = sparseOfs - last_rest_size
  local this_rest_size = last_rest_size + sparseLen
  last_rest_size = 0
  repeat
    if sparse_format_type == SPARSE_INFO.sparse_total_head then
      this_rest_size = this_rest_size - SPARSE_INFO.sparse_header_size
      sparseOfs = sparseOfs + SPARSE_INFO.sparse_header_size
      sparse_format_type = SPARSE_INFO.sparse_chunk_head
    elseif sparse_format_type == SPARSE_INFO.sparse_chunk_head then
      if this_rest_size < SPARSE_INFO.chunk_header_size then
        last_rest_size = this_rest_size
        ret = sparseBuf.MemCopy({
          srcBuf = sparseBuf,
          srcOffset = sparseOfs,
          pos = para.sparseOfs - this_rest_size,
          nBytes = this_rest_size
        })
        if not ret then
          break
        end
        this_rest_size = 0
        break
      end
      local chunk_type = sparseBuf.GetMemVal2Int16(sparseOfs + 0)
      local chunk_sz = sparseBuf.GetMemVal2Int32(sparseOfs + 4)
      local total_sz = sparseBuf.GetMemVal2Int32(sparseOfs + 8)
      chunk_length = chunk_sz * blk_size
      sparseOfs = sparseOfs + SPARSE_INFO.chunk_header_size
      this_rest_size = this_rest_size - SPARSE_INFO.chunk_header_size
      if chunk_type == SPARSE_INFO.chunk_type_raw then
        if total_sz ~= chunk_length + SPARSE_INFO.chunk_header_size then
          ErrPrintL("bad chunk size")
          ret = false
          break
        end
        sparse_format_type = SPARSE_INFO.sparse_chunk_data
      elseif chunk_type == SPARSE_INFO.chunk_type_null then
        if total_sz ~= 12 then
          ErrPrintL("bad chunk size")
          ret = false
          break
        end
        flash_start = flash_start + chunk_length / 512
        sparse_format_type = SPARSE_INFO.sparse_chunk_head
      elseif chunk_type == SPARSE_INFO.chunk_type_fill then
        if total_sz ~= SPARSE_INFO.chunk_header_size + 4 then
          ErrPrintL("bad chunk size")
          ret = false
          break
        end
        sparse_format_type = SPARSE_INFO.sparse_fill_data
      else
        MsgPrintL("unknow chunk type")
        ret = false
        break
      end
      handled_chunk = handled_chunk + 1
    elseif sparse_format_type == SPARSE_INFO.sparse_fill_data then
      if 4 <= this_rest_size then
        flash_start = flash_start + chunk_length / 512
        sparseOfs = sparseOfs + 4
        this_rest_size = this_rest_size - 4
        sparse_format_type = SPARSE_INFO.sparse_chunk_head
      else
        ret = sparseBuf.MemCopy({
          srcBuf = sparseBuf,
          srcOffset = sparseOfs,
          pos = para.sparseOfs - this_rest_size,
          nBytes = this_rest_size
        })
        if not ret then
          break
        end
        last_rest_size = this_rest_size
        this_rest_size = 0
        sparse_format_type = SPARSE_INFO.sparse_fill_data
      end
    elseif sparse_format_type == SPARSE_INFO.sparse_chunk_data then
      local unenough_len = chunk_length >= this_rest_size and chunk_length - this_rest_size or 0
      local downLen = 0
      if unenough_len == 0 then
        downLen = chunk_length
        ret = tlFesDev.FesDownData({
          addr = flash_start,
          len = downLen,
          dataBuf = sparseBuf,
          bufOffset = sparseOfs,
          uiPromptOnce = para.uiPromptOnce,
          uiCbProgress = para.uiCbProgress,
          totalUnPromptLenInPkt = para.totalUnPromptLenInPkt,
          uiCurrent = para.uiCurrent,
          data_tag = para.data_tag,
          media_index = para.media_index
        })
        if not ret then
          ErrPrintL("Failed to down to FES")
          break
        end
        flash_start = flash_start + chunk_length / 512
        sparseOfs = sparseOfs + chunk_length
        this_rest_size = this_rest_size - chunk_length
        chunk_length = 0
        sparse_format_type = SPARSE_INFO.sparse_chunk_head
      else
        if this_rest_size < 8192 then
          last_rest_size = this_rest_size
          ret = sparseBuf.MemCopy({
            srcBuf = sparseBuf,
            srcOffset = sparseOfs,
            pos = para.sparseOfs - this_rest_size,
            nBytes = this_rest_size
          })
          if not ret then
            break
          end
          this_rest_size = 0
          break
        end
        if unenough_len < 4096 then
          downLen = this_rest_size + unenough_len - 4096
        else
          downLen = this_rest_size - this_rest_size % 512
        end
        ret = tlFesDev.FesDownData({
          addr = flash_start,
          len = downLen,
          dataBuf = sparseBuf,
          bufOffset = sparseOfs,
          uiPromptOnce = para.uiPromptOnce,
          uiCbProgress = para.uiCbProgress,
          totalUnPromptLenInPkt = para.totalUnPromptLenInPkt,
          uiCurrent = para.uiCurrent,
          data_tag = para.data_tag,
          media_index = para.media_index
        })
        if not ret then
          ErrPrintL("Failed to down to FES")
          break
        end
        sparseOfs = sparseOfs + downLen
        flash_start = flash_start + downLen / 512
        chunk_length = chunk_length - downLen
        this_rest_size = this_rest_size - downLen
        ret = sparseBuf.MemCopy({
          srcBuf = sparseBuf,
          srcOffset = sparseOfs,
          pos = para.sparseOfs - this_rest_size,
          nBytes = this_rest_size
        })
        if not ret then
          break
        end
        last_rest_size = this_rest_size
        this_rest_size = 0
        sparse_format_type = SPARSE_INFO.sparse_chunk_data
      end
    else
      ErrPrintL("chunk unknown status !!!")
      ret = false
      break
    end
  until this_rest_size <= 0
  retPara.sparse_format_type = sparse_format_type
  retPara.chunk_length = chunk_length
  retPara.flash_start = flash_start
  retPara.last_rest_size = last_rest_size
  return ret, retPara
end

local function fes_down_sparse_item(para)
  if "table" ~= type(para) then
    ErrPrintL("type should be table, but %s", type(para))
    return nil
  end
  local partNum, partName, mainType, subType, tlBufImg, tlFesDev, tlImg, addr, maxLen, bufOffset, uiStart, uiEnd, uiCbProgress, data_tag, media_index = para.partNum, para.partName, para.mainType, para.subType, para.tlBufImg, para.tlFesDev, para.tlImg, para.addr, para.maxLen, para.bufOffset, para.uiStepStart, para.uiStepEnd, para.uiCbProgress, para.data_tag, para.media_index
  if "string" ~= type(mainType) or "string" ~= type(subType) or "table" ~= type(tlBufImg) or "table" ~= type(tlFesDev) or "table" ~= type(tlImg) or "number" ~= type(addr) or "number" ~= type(maxLen) then
    ErrPrintL("type should string, string, table, table, table, number,number, but(%s, %s, %s, %s, %s, %s, %s)", type(mainType), type(subType), type(tlBufImg), type(tlFesDev), type(tlImg), type(addr), type(maxLen))
    return nil
  end
  local theItem = tlImg.Item(mainType, subType)
  if not theItem then
    ErrPrintL("Fail to open item")
    return false
  end
  local itemSz = theItem.ItemSize()
  if maxLen < itemSz then
    ErrPrintL("itemSz(0x%x)>maxLen(0x%x)", itemSz, maxLen)
    theItem.Close()
    return false
  end
  MsgPrintL("item size :%d M", itemSz / 1048576)
  local totalUnPromptLenInPkt, uiCurrent = 0, uiStart
  local uiPromptOnce = 0
  if uiCbProgress then
    local uiPromptTimes = uiEnd + 1 - uiStart
    uiPromptOnce = itemSz / uiPromptTimes
  end
  local sparse_magic = tlBufImg.GetMemVal2Int32(0)
  local sparse_major_ver = tlBufImg.GetMemVal2Int16(4)
  local sparse_head_size = tlBufImg.GetMemVal2Int16(8)
  local chunk_head_size = tlBufImg.GetMemVal2Int16(10)
  local blk_size = tlBufImg.GetMemVal2Int16(12)
  local total_blk = tlBufImg.GetMemVal2Int16(16)
  local total_chunk = tlBufImg.GetMemVal2Int16(20)
  MsgPrintL("magic = %x", sparse_magic)
  MsgPrintL("blk_size = %x", blk_size)
  MsgPrintL("total_chunk = %x", total_chunk)
  MsgPrintL("tlBufImg size = %x", tlBufImg.GetSize())
  local chunk_cnt = 0
  local chunk_addr = addr
  local ret = false
  local sparseBuf = Tools_Buffer(10551296)
  local sparseOfs = 65536
  local lastLeft = 0
  local pp = sparseBuf.BuffShift(sparseOfs)
  local totalReadLen = 0
  local bufLen = sparseBuf.GetSize() - sparseOfs
  local retPara = {
    last_rest_size = 0,
    flash_start = addr,
    chunk_length = 0,
    sparse_format_type = SPARSE_INFO.sparse_total_head
  }
  repeat
    local leftLen = itemSz - totalReadLen
    local wantLen = bufLen < leftLen and bufLen or leftLen
    ret = theItem.Read(pp, wantLen)
    if not ret then
      ErrPrinL("read Item data fail")
      break
    end
    ret, retPara = parse_and_down_chunk({
      tlFesDev = tlFesDev,
      sparseBuf = sparseBuf,
      sparseOfs = sparseOfs,
      sparseLen = wantLen,
      sparseBlkSize = blk_size,
      uiPromptOnce = uiPromptOnce,
      uiCbProgress = uiCbProgress,
      totalUnPromptLenInPkt = totalUnPromptLenInPkt,
      uiCurrent = uiCurrent,
      data_tag = data_tag,
      media_index = media_index,
      retPara = retPara
    })
    if not ret then
      ErrPrintL("parse and down chunk error")
      break
    end
    totalReadLen = totalReadLen + wantLen
    if uiCbProgress then
      local steps = totalReadLen / uiPromptOnce
      steps = steps - steps % 1
      uiCurrent = uiStart + steps
      totalUnPromptLenInPkt = totalReadLen - steps * uiPromptOnce
    end
  until itemSz <= totalReadLen
  MsgPrintL("handled chunk = %x total_chunk = %x", handled_chunk, total_chunk)
  sparseBuf.Free()
  theItem.Close()
  return ret
end

local function fes_down_sysrecovery_item(para)
  if "table" ~= type(para) then
    ErrPrintL("type should be table, but %s", type(para))
    return nil
  end
  local tlBufImg, tlFesDev, addr, maxLen, bufOffset, uiStart, uiEnd, uiCbProgress, data_tag, media_index = para.tlBufImg, para.tlFesDev, para.addr, para.maxLen, para.bufOffset, para.uiStepStart, para.uiStepEnd, para.uiCbProgress, para.data_tag, para.media_index
  if "table" ~= type(tlBufImg) or "table" ~= type(tlFesDev) or "number" ~= type(addr) or "number" ~= type(maxLen) then
    ErrPrintL("arg nedd table, table, number,number, but(%s, %s, %s, %s)", type(tlBufImg), type(tlFesDev), type(addr), type(maxLen))
    return nil
  end
  local itemSz = toolsInitPara.ImgLenLow + toolsInitPara.ImgLenHigh * 4294967296
  local imgFile = Tools_File(toolsInitPara.imgFilePath, "rb+")
  if not imgFile then
    ErrPrintL("Fail to open %s", toolsInitPara.imgFilePath)
    return false
  end
  if maxLen < itemSz then
    ErrPrintL("recover -->itemSz(0x%x)>maxLen(0x%x)", itemSz, maxLen)
    imgFile.Close()
    return false
  end
  local totalUnPromptLenInPkt, uiCurrent = 0, uiStart
  local uiPromptOnce = 0
  if uiCbProgress then
    local uiPromptTimes = uiEnd + 1 - uiStart
    uiPromptOnce = itemSz / uiPromptTimes
  end
  bufOffset = bufOffset or 0
  local pp = tlBufImg.BuffShift(bufOffset)
  local totalReadLen, ret = 0, false
  local bufLen = tlBufImg.GetSize() - bufOffset
  repeat
    local leftLen = itemSz - totalReadLen
    local downAddr = FES_MEDIA_INDEX.DRAM == media_index and addr + totalReadLen or addr + totalReadLen / 512
    local wantLen = bufLen < leftLen and bufLen or leftLen
    ret = imgFile.Read(pp, wantLen)
    if not ret then
      ErrPrintL("Fail to read item")
      break
    end
    ret = tlFesDev.FesDownData({
      addr = downAddr,
      len = wantLen,
      dataBuf = tlBufImg,
      bufOffset = bufOffset,
      uiPromptOnce = uiPromptOnce,
      uiCbProgress = uiCbProgress,
      totalUnPromptLenInPkt = totalUnPromptLenInPkt,
      uiCurrent = uiCurrent,
      data_tag = data_tag,
      media_index = media_index
    })
    if not ret then
      imgFile.Close()
      ErrPrintL("Failed to down to FES")
      break
    end
    totalReadLen = totalReadLen + wantLen
    if uiCbProgress then
      local steps = totalReadLen / uiPromptOnce
      steps = steps - steps % 1
      uiCurrent = uiStart + steps
      totalUnPromptLenInPkt = totalReadLen - steps * uiPromptOnce
    end
  until itemSz <= totalReadLen
  imgFile.Close()
  return ret
end

local function fes_verify_transfer_value(para)
  if "table" ~= type(para) then
    ErrPrintL("verify status :argument check error")
    return nil
  end
  local tlFesDev, value, start, size = para.tlFesDev, para.value, para.start, para.size
  local verifyBuf = Tools_Buffer(12)
  if not verifyBuf then
    ErrPrintL("malloc mem fail")
    return nil
  end
  local time = 5
  for i = 1, time do
    local ret = tlFesDev.Fex_VerifyValue({
      dataBuf = verifyBuf,
      start = start,
      size = size
    })
    if not ret then
      ErrPrintL("verify status error")
      verifyBuf.Free()
      return nil
    end
    local flag = verifyBuf.GetMemVal2Int32(0)
    local media_crc = verifyBuf.GetMemVal2Int32(8)
    if flag == 1784772099 then
      verifyBuf.Free()
      MsgPrintL("Verify:start = %x ,size = %x ,pc_crc = %x, media crc = %x", start, size, value, media_crc)
      return media_crc == value and true or false
    end
    ToolsSuspend(300)
  end
  verifyBuf.Free()
  return false
end

local function get_item_size(para)
  if "string" ~= type(para.mainType) or "string" ~= type(para.subType) or "table" ~= type(para.tlImg) then
    ErrPrintL("arg (string string,table) need buf (%s,%s,%s)", type(para.mianType), type(para.subType), type(para.tlImg))
    return nil
  end
  local mainType, subType, tlImg = para.mainType, para.subType, para.tlImg
  local theItem = tlImg.Item(mainType, subType)
  if not theItem then
    ErrPrintL("Fail to open item")
    return nil
  end
  local itemSz = theItem.ItemSize()
  theItem.Close()
  return itemSz
end

local function sparse_format_probe(para)
  if "string" ~= type(para.mainType) or "string" ~= type(para.subType) or "table" ~= type(para.tlBufImg) or "table" ~= type(para.tlImg) then
    ErrPrintL("arg (string string,table,table) need buf (%s,%s,%s,%s)", type(para.mianType), type(para.subType), type(para.tlBufImg), type(para.tlImg))
    return nil
  end
  local mainType, subType, tlImg = para.mainType, para.subType, para.tlImg
  local header_buf = para.tlBufImg
  local theItem = tlImg.Item(mainType, subType)
  if not theItem then
    ErrPrintL("Fail to open item")
    return nil
  end
  local itemSz = theItem.ItemSize()
  local readLen = math.min(itemSz, 512)
  local ret = theItem.Read(header_buf.BuffShift(0), readLen)
  if not ret then
    ErrPrintL("Fail to Read item data")
    return nil
  end
  theItem.Close()
  local sparse_magic = header_buf.GetMemVal2Int32(0)
  local sparse_major_ver = header_buf.GetMemVal2Int16(4)
  local sparse_head_size = header_buf.GetMemVal2Int16(8)
  local chunk_head_size = header_buf.GetMemVal2Int16(10)
  if SPARSE_INFO.sparse_magic ~= sparse_magic or SPARSE_INFO.sparse_major_ver ~= sparse_major_ver or SPARSE_INFO.sparse_header_size ~= sparse_head_size or SPARSE_INFO.chunk_header_size ~= chunk_head_size then
    return false
  end
  MsgPrintL("find a sparse format part,%s", subType)
  return true
end

local function fes_down_dlmap_file(para)
  if "table" ~= type(para.dlmap_buf) or "table" ~= type(para.tlFesDev) or "table" ~= type(para.tlBufImg) or "table" ~= type(para.tlImg) or "table" ~= type(para.mbr_part_key) then
    ErrPrintL("argument check error")
    return nil
  end
  local tlFesDev, tlBufImg = para.tlFesDev, para.tlBufImg
  local mbr_part_key = para.mbr_part_key
  local dlmap_buff = para.dlmap_buf
  local crc32 = dlmap_buff.GetMemVal2Int32(0)
  local version = dlmap_buff.GetMemVal2Int32(4)
  local magic = dlmap_buff.GetMemVal2Chars({pos = 8, nLen = 8})
  local part_cnt = dlmap_buff.GetMemVal2Int32(16)
  MsgPrintL("------------dlmap dump--------------")
  MsgPrintL("crc32     = 0x%x", crc32)
  MsgPrintL("version   = 0x%x", version)
  MsgPrintL("magic     = %s", magic)
  MsgPrintL("part_cnt  = %d", part_cnt)
  if part_cnt == 0 then
    MsgPrintL("No Part need to down")
    return true
  end
  local ret = tlFesDev.Fex_ProbeFlashSize({dataBuf = tlBufImg})
  if not ret then
    ErrPrintL("probe flash size fail")
    return false
  end
  local flash_size = tlBufImg.GetMemVal2Int32(0)
  MsgPrintL("flash size is : %d Sectors", flash_size)
  local part_ofs = 32
  local uiStepStart, uiStepEnd, uiCallBack = para.uiStepStart, para.uiStepEnd, para.uiCallBack
  local aPartUiSteps = (uiStepEnd - uiStepStart + 1) / part_cnt
  for i = 0, part_cnt - 1 do
    local name = dlmap_buff.GetMemVal2Chars({
      pos = part_ofs + 0,
      nLen = 16
    })
    local addrhi = dlmap_buff.GetMemVal2Int32(part_ofs + 16)
    local addrlo = dlmap_buff.GetMemVal2Int32(part_ofs + 20)
    local lenhi = dlmap_buff.GetMemVal2Int32(part_ofs + 24)
    local lenlo = dlmap_buff.GetMemVal2Int32(part_ofs + 28)
    local dl_filename = dlmap_buff.GetMemVal2Chars({
      pos = part_ofs + 32,
      nLen = 16
    })
    local vf_filename = dlmap_buff.GetMemVal2Chars({
      pos = part_ofs + 48,
      nLen = 16
    })
    local encrypt = dlmap_buff.GetMemVal2Int32(part_ofs + 64)
    local verify = dlmap_buff.GetMemVal2Int32(part_ofs + 68)
    MsgPrintL("name = %s addrhi=0x%x addrlo = 0x%x  lenhi = 0x%x lenlo = 0x%x  file = %s, en=%d,vf=%d", name, addrhi, addrlo, lenhi, lenlo, dl_filename, encrypt, verify)
    local partUiStepStart = uiStepStart + i * aPartUiSteps
    local partUiStepEnd = partUiStepStart + aPartUiSteps
    if "UDISK" == name then
      lenlo = flash_size - addrlo
      lenhi = 0
    end
    local part_size = lenlo + lenhi * 4294967296
    part_size = part_size * 512
    local mainType, subType = IMG_ITEM.main.USR_FS, dl_filename
    local pack_len = 0
    if "sysrecovery" == name then
      packet_len = toolsInitPara.ImgLenLow + toolsInitPara.ImgLenHigh * 4294967296
      ret = fes_down_sysrecovery_item({
        tlBufImg = para.tlBufImg,
        tlFesDev = para.tlFesDev,
        tlImg = para.tlImg,
        addr = addrlo,
        maxLen = part_size,
        bufOffset = 0,
        uiStepStart = partUiStepStart,
        uiStepEnd = partUiStepEnd,
        uiCbProgress = uiCallBack.SendProgress,
        data_tag = 0,
        media_index = FES_MEDIA_INDEX.FLASH_LOG
      })
      if not ret then
        ErrPrintL("down partition %s error", name)
        break
      end
      MsgPrintL("down sysrecovery partition ok")
    else
      packet_len = get_item_size({
        mainType = mainType,
        subType = subType,
        tlImg = para.tlImg
      })
      if packet_len == nil then
        ErrPrintL("Fail to Get Item size")
        ret = false
        break
      end
      local sparseFlag = sparse_format_probe({
        mainType = mainType,
        subType = subType,
        tlBufImg = para.tlBufImg,
        tlImg = para.tlImg
      })
      if nil == sparseFlag then
        ret = false
        break
      end
      if sparseFlag then
        ret = fes_down_sparse_item({
          partNum = i,
          partName = name,
          mainType = mainType,
          subType = subType,
          tlBufImg = para.tlBufImg,
          tlFesDev = para.tlFesDev,
          tlImg = para.tlImg,
          addr = addrlo,
          maxLen = part_size,
          bufOffset = 0,
          uiStepStart = partUiStepStart,
          uiStepEnd = partUiStepEnd,
          uiCbProgress = uiCallBack.SendProgress,
          data_tag = 0,
          media_index = FES_MEDIA_INDEX.FLASH_LOG
        })
        if not ret then
          ErrPrintL("down partition %s error", name)
          break
        end
      else
        ret = fes_down_normal_item({
          partNum = i,
          partName = name,
          mainType = mainType,
          subType = subType,
          tlBufImg = para.tlBufImg,
          tlFesDev = para.tlFesDev,
          tlImg = para.tlImg,
          addr = addrlo,
          maxLen = part_size,
          bufOffset = 0,
          uiStepStart = partUiStepStart,
          uiStepEnd = partUiStepEnd,
          uiCbProgress = uiCallBack.SendProgress,
          data_tag = 0,
          media_index = FES_MEDIA_INDEX.FLASH_LOG,
          mbr_part_key = mbr_part_key
        })
        if not ret then
          ErrPrintL("down partition %s error", name)
          break
        end
      end
    end
    if verify == 1 and "system" ~= name and "vendor" ~= name then
      if "string" ~= type(vf_filename) then
        ErrPrintL("vf filename must be string")
        ret = false
        break
      end
      MsgPrintL("need verify:%d,%s", verify, vf_filename)
      local mainType, subType = IMG_ITEM.main.USR_FS, vf_filename
      local tlBuf, tlImg = para.tlBufImg, para.tlImg
      ret = tlImg.save_item_to_mem(mainType, subType, tlBuf)
      if not ret then
        ErrPrintL("fail to read vf_file:%s", vf_filename)
        break
      end
      local value = tlBuf.GetMemVal2Int32(0)
      ret = fes_verify_transfer_value({
        tlFesDev = tlFesDev,
        start = addrlo,
        size = packet_len,
        value = value
      })
      if not ret then
        break
      end
    end
    part_ofs = part_ofs + 72
  end
  return ret
end

local function fes_verify_transfer_status(para)
  if "table" ~= type(para) then
    ErrPrintL("verify status :argument check error")
    return nil
  end
  local tlFesDev, tag = para.tlFesDev, para.tag
  local verifyBuf = Tools_Buffer(12)
  if not verifyBuf then
    ErrPrintL("malloc mem fail")
    return nil
  end
  local time = 5
  for i = 1, time do
    local ret = tlFesDev.Fex_VerifyStatus({dataBuf = verifyBuf, tag = tag})
    if not ret then
      ErrPrintL("verify status error")
      verifyBuf.Free()
      return nil
    end
    local flag = verifyBuf.GetMemVal2Int32(0)
    local media_crc = verifyBuf.GetMemVal2Int32(8)
    if flag == 1784772099 then
      verifyBuf.Free()
      MsgPrintL("Verify: media crc = %x", media_crc)
      return media_crc == 0 and true or nil
    end
    ToolsSuspend(300)
  end
  verifyBuf.Free()
  return false
end

local function fes_down_fullimage_size(para)
  if "table" ~= type(para.tlFesDev) or "table" ~= type(para.tlBufImg) then
    ErrPrintL("arguments check error: table, table but(%s,%s)", type(para.tlFesDev), type(para.tlBufImg))
    return nil
  end
  local tlFesDev, data_buf = para.tlFesDev, para.tlBufImg
  ret = tlFesDev.FesDownData({
    addr = 0,
    len = 8,
    dataBuf = data_buf,
    bufOffset = 0,
    uiPromptOnce = 0,
    uiCbProgress = false,
    totalUnPromptLenInPkt = 0,
    uiCurrent = 0,
    data_tag = SUNXI_EFEX_TAG.sunxi_efex_full_size_tag,
    media_index = FES_MEDIA_INDEX.DRAM
  })
  if not ret then
    ErrPrintL("Fail to Fes Down Data")
    data_buf.Free()
    return false
  end
  ret = fes_verify_transfer_status({
    tlFesDev = tlFesDev,
    tag = SUNXI_EFEX_TAG.sunxi_efex_full_size_tag
  })
  if not ret then
    ErrPrintL("Verify status error")
    return false
  end
  return true
end

local function fes_down_full_image(para)
  if "table" ~= type(para.tlFesDev) or "table" ~= type(para.tlImg) then
    ErrPrintL("arguments check error: table, table,but(%s,%s)", type(para.tlFesDev), type(para.image))
    return nil
  end
  local tlFesDev, tlBufImg = para.tlFesDev, para.tlBufImg
  local full_img_exist = false
  local szMainType, szSubType = IMG_ITEM.main.MP_FILE, IMG_ITEM.sub.MP_FILE.full_image
  local theItem = para.tlImg.Item(szMainType, szSubType)
  if not theItem then
    ErrPrintL("Fail to open full_image")
    return false, full_img_exist
  end
  full_img_exist = true
  local ret = tlFesDev.Fex_ProbeFlashSize({dataBuf = tlBufImg})
  if not ret then
    ErrPrintL("probe flash size fail")
    return false, full_img_exist
  end
  local flash_size = tlBufImg.GetMemVal2Int32(0)
  MsgPrintL("flash size is : %d Sectors", flash_size)
  local itemSz = theItem.ItemSize()
  para.tlBufImg.Zero()
  para.tlBufImg.SetMemValWithInt32({val = itemSz})
  ret = fes_down_fullimage_size({
    tlFesDev = para.tlFesDev,
    tlBufImg = para.tlBufImg
  })
  if not ret then
    MsgPrintL("down full image size fail!!!")
    return false, full_img_exist
  end
  ret = fes_down_normal_item({
    partNum = 0,
    partName = "fullimage",
    mainType = szMainType,
    subType = szSubType,
    tlBufImg = para.tlBufImg,
    tlFesDev = para.tlFesDev,
    tlImg = para.tlImg,
    addr = 0,
    maxLen = flash_size * 512,
    bufOffset = 0,
    uiStepStart = para.uiStepStart,
    uiStepEnd = para.uiStepEnd,
    uiCbProgress = para.uiCallBack.SendProgress,
    data_tag = 0,
    media_index = FES_MEDIA_INDEX.FLASH_LOG,
    mbr_part_key = para.mbr_part_key
  })
  if not ret then
    ErrPrintL("down full image error")
    return false, full_img_exist
  end
  return true, full_img_exist
end

local function fes_get_storage_type(para)
  local ret = false
  local tmpBuf = Tools_Buffer(16)
  ret = para.tlFesDev.Fex_QueryStorage({dataBuf = tmpBuf})
  if not ret then
    ErrPrintL("Fex_QueryStorage fail")
    return false
  end
  local storage_type = tmpBuf.GetMemVal2Int32(0)
  MsgPrintL("storge type is %d (0:nand 1-2:card 3:spinor)", storage_type)
  tmpBuf.Free()
  return storage_type
end

local function fes_down_partition(para)
  if "table" ~= type(para.tlFesDev) or "table" ~= type(para.tlImg) or "table" ~= type(para.tlBufImg) then
    ErrPrintL("arguments check error: table, table,table but(%s,%s,%s)", type(para.tlFesDev), type(para.image), type(para.tlBufImg))
    return nil
  end
  local image, tlFesDev, dlLen = para.tlImg, para.tlFesDev, 16384
  local ret = tlFesDev.Fex_SetFlashOnOff({flash_on = 1, flash_type = 0})
  if not ret then
    ErrPrintL("open flash fail")
    return false
  end
  local dlmap_buf = Tools_Buffer(16384)
  if not dlmap_buf then
    ErrPrintL("Fail to alloc buffer for download map file")
    return nil
  end
  local szMainType, szSubType = IMG_ITEM.main.MP_FILE, IMG_ITEM.sub.MP_FILE.dlinfo
  local realLen = image.save_item_to_mem(szMainType, szSubType, dlmap_buf)
  MsgPrintL("dl file :save item to mem :(%s,%s) realLen(%d)", szMainType, szSubType, realLen)
  if realLen ~= dlLen or not realLen then
    ErrPrintL("dl file :save item to mem fail:(%s,%s) ", szMainType, szSubType)
    dlmap_buf.Free()
    return nil
  end
  local cal_crc = dlmap_buf.CalCrc32({
    pos = 4,
    nBytes = dlLen - 4
  })
  local file_crc = dlmap_buf.GetMemVal2Int32(0)
  if cal_crc ~= file_crc then
    ErrPrintL("dl map file  cal crc error: %x != file(%x)", cal_crc, file_crc)
    dlmap_buf.Free()
    return false
  end
  para.dlmap_buf = dlmap_buf
  ret = fes_down_dlmap_file(para)
  dlmap_buf.Free()
  if not ret then
    ErrPrintL("fes down partition fail")
    tlFesDev.Fex_SetFlashOnOff({flash_on = 0, flash_type = 0})
    return false
  end
  ret = tlFesDev.Fex_SetFlashOnOff({flash_on = 0, flash_type = 0})
  if not ret then
    ErrPrintL("close flash fail")
    return false
  end
  return true
end

local function fes_down_erase_flag(para)
  if "table" ~= type(para.tlFesDev) or "table" ~= type(para.tlImg) or "table" ~= type(para.tlBufImg) then
    ErrPrintL("arguments check error: table, table,table but(%s,%s,%s)", type(para.tlFesDev), type(para.image), type(para.tlBufImg))
    return nil
  end
  local tlFesDev, tlBufImg = para.tlFesDev, para.tlBufImg
  tlBufImg.SetMemValWithInt32({
    val = toolsInitPara.erase_flag
  })
  local ret = tlFesDev.FesDownData({
    addr = 0,
    len = 16,
    dataBuf = tlBufImg,
    bufOffset = 0,
    uiPromptOnce = 0,
    uiCbProgress = false,
    totalUnPromptLenInPkt = 0,
    uiCurrent = 0,
    data_tag = SUNXI_EFEX_TAG.sunxi_efex_erase_tag,
    media_index = FES_MEDIA_INDEX.DRAM
  })
  if not ret then
    ErrPrintL("Fail to Fes Down Data")
    return false
  end
  ret = fes_verify_transfer_status({
    tlFesDev = tlFesDev,
    tag = SUNXI_EFEX_TAG.sunxi_efex_erase_tag
  })
  if not ret then
    ErrPrintL("Verify status error")
    return false
  end
end

local function fes_down_mbr(para)
  if "table" ~= type(para.tlFesDev) or "table" ~= type(para.tlImg) or "table" ~= type(para.tlBufImg) or "table" ~= type(para.mbr_part_keydata) then
    ErrPrintL("arguments check error: table, table,table but(%s,%s,%s)", type(para.tlFesDev), type(para.image), type(para.tlBufImg))
    return nil
  end
  local image, tlFesDev, data_buf = para.tlImg, para.tlFesDev, para.tlBufImg
  local mbr_part_keydata = para.mbr_part_keydata
  local mbr_size, mbr_copy_num = 16384, 4
  local szMainType, szSubType = IMG_ITEM.main.MP_FILE, IMG_ITEM.sub.MP_FILE.sunxi_mbr
  local realLen = image.save_item_to_mem(szMainType, szSubType, data_buf)
  MsgPrintL("save item to mem :(%s,%s) realLen(%d)", szMainType, szSubType, realLen)
  if not realLen then
    ErrPrintL("save item to mem fail:(%s,%s) ", szMainType, szSubType)
    return false
  end
  mbr_copy_num = realLen / 16384
  local buf_size = mbr_size * mbr_copy_num
  local tmp_buf = data_buf
  local flag = false
  local ok_copy = 0
  for i = 0, mbr_copy_num - 1 do
    local cal_crc = tmp_buf.CalCrc32({
      pos = i * mbr_size + 4,
      nBytes = mbr_size - 4
    })
    local file_crc = tmp_buf.GetMemVal2Int32(i * mbr_size)
    if cal_crc == file_crc then
      flag = true
      ok_copy = i
      break
    end
  end
  if not flag then
    ErrPrintL("mbr check crc error")
    return false
  end
  local partStSz = 128
  local partStOfs = 32
  local keydataOfs = 52
  local partNum = data_buf.GetMemVal2Int32(ok_copy * mbr_size + 24)
  for i = 0, partNum do
    local partName = data_buf.GetMemVal2Chars({
      pos = ok_copy * mbr_size + partStOfs + partStSz * i + 32,
      nLen = 16
    })
    mbr_part_keydata[partName] = data_buf.GetMemVal2Int32(ok_copy * mbr_size + partStOfs + partStSz * i + keydataOfs)
    MsgPrintL("name = %s, keydata = %x", partName, mbr_part_keydata[partName])
  end
  local ret = tlFesDev.FesDownData({
    addr = 0,
    len = buf_size,
    dataBuf = data_buf,
    bufOffset = 0,
    uiPromptOnce = 0,
    uiCbProgress = false,
    totalUnPromptLenInPkt = 0,
    uiCurrent = 0,
    data_tag = SUNXI_EFEX_TAG.sunxi_efex_mbr_tag,
    media_index = FES_MEDIA_INDEX.DRAM
  })
  if not ret then
    ErrPrintL("Fail to Fes Down Data")
    return false
  end
  ret = fes_verify_transfer_status({
    tlFesDev = tlFesDev,
    tag = SUNXI_EFEX_TAG.sunxi_efex_mbr_tag
  })
  if not ret then
    ErrPrintL("Verify status error")
    return false
  end
  MsgPrintL("down mbr success!!!")
  return true
end

local function fes_down_uboot(para)
  if "table" ~= type(para.tlFesDev) or "table" ~= type(para.tlImg) or "table" ~= type(para.tlBufImg) then
    ErrPrintL("arguments check error: table, table,table but(%s,%s,%s)", type(para.tlFesDev), type(para.image), type(para.tlBufImg))
    return nil
  end
  local image, tlFesDev, data_buf = para.tlImg, para.tlFesDev, para.tlBufImg
  local szMainType, szSubType = IMG_ITEM.main.MP_FILE, IMG_ITEM.sub.MP_FILE.uboot
  local storage_type = fes_get_storage_type({tlFesDev = tlFesDev})
  local ret = tlFesDev.Fex_ProbeBootPackageMode({dataBuf = data_buf})
  if not ret then
    ErrPrintL("probe boot package fail")
    return false
  end
  local bootpackage_mode = data_buf.GetMemVal2Int32(0)
  MsgPrintL("bootpackage_mode : %d ", bootpackage_mode)
  if bootpackage_mode == Cfg.Boot_Package_Mode.SUNXI_BOOT_FILE_NORMAL then
    szSubType = IMG_ITEM.sub.MP_FILE.uboot
  elseif bootpackage_mode == Cfg.Boot_Package_Mode.SUNXI_BOOT_FILE_PKG then
    if storage_type == 3 then
      szSubType = IMG_ITEM.sub.MP_FILE.boot_package_nor
    else
      szSubType = IMG_ITEM.sub.MP_FILE.boot_package
    end
  elseif bootpackage_mode == Cfg.Boot_Package_Mode.SUNXI_BOOT_FILE_TOC then
    szSubType = IMG_ITEM.sub.MP_FILE.toc1
  end
  local realLen = image.save_item_to_mem(szMainType, szSubType, data_buf)
  MsgPrintL("save item to mem :(%s,%s) realLen(%d)", szMainType, szSubType, realLen)
  if not realLen then
    ErrPrintL("save item to mem fail:(%s,%s) ", szMainType, szSubType)
    return false
  end
  local ret = tlFesDev.FesDownData({
    addr = 0,
    len = realLen,
    dataBuf = data_buf,
    bufOffset = 0,
    uiPromptOnce = 0,
    uiCbProgress = false,
    totalUnPromptLenInPkt = 0,
    uiCurrent = 0,
    data_tag = SUNXI_EFEX_TAG.sunxi_efex_uboot_tag,
    media_index = FES_MEDIA_INDEX.DRAM
  })
  if not ret then
    ErrPrintL("Fail to Fes Down Data")
    data_buf.Free()
    return false
  end
  ret = fes_verify_transfer_status({
    tlFesDev = tlFesDev,
    tag = SUNXI_EFEX_TAG.sunxi_efex_uboot_tag
  })
  if not ret then
    ErrPrintL("Verify status error")
    return false
  end
  MsgPrintL("down uboot success!!!")
  return true
end

local function fes_down_boot0(para)
  if "table" ~= type(para.tlFesDev) or "table" ~= type(para.tlImg) or "table" ~= type(para.tlBufImg) then
    ErrPrintL("arguments check error: table, table,table but(%s,%s,%s)", type(para.tlFesDev), type(para.image), type(para.tlBufImg))
    return nil
  end
  local image, tlFesDev, data_buf = para.tlImg, para.tlFesDev, para.tlBufImg
  local szMainType, szSubType
  local ret = tlFesDev.Fex_QueryStorage({dataBuf = data_buf})
  if not ret then
    ErrPrintL("Fex_QueryStorage fail")
    return false
  end
  local storage_type = data_buf.GetMemVal2Int32(0)
  MsgPrintL("storge type is %d (0:nand 1-2:card 3:spinor)", storage_type)
  local ret = tlFesDev.Fex_ProbeBootPackageMode({dataBuf = data_buf})
  if not ret then
    ErrPrintL("probe boot package fail")
    return false
  end
  local bootpackage_mode = data_buf.GetMemVal2Int32(0)
  MsgPrintL("bootpackage_mode : %d ", bootpackage_mode)
  if bootpackage_mode == Cfg.Boot_Package_Mode.SUNXI_BOOT_FILE_TOC then
    szMainType, szSubType = IMG_ITEM.main.MP_FILE, IMG_ITEM.sub.MP_FILE.toc0
  elseif storage_type == 0 then
    szMainType, szSubType = IMG_ITEM.main.BOOT, IMG_ITEM.sub.MP_FILE.boot0_nand
  elseif storage_type == 1 or storage_type == 2 then
    szMainType, szSubType = IMG_ITEM.main.MP_FILE, IMG_ITEM.sub.MP_FILE.boot0_sdcard
  elseif storage_type == 3 then
    szMainType, szSubType = IMG_ITEM.main.MP_FILE, IMG_ITEM.sub.MP_FILE.boot0_spinor
  else
    ErrPrintL("storge type invalid")
    return false
  end
  local realLen = image.save_item_to_mem(szMainType, szSubType, data_buf)
  MsgPrintL("save item to mem :(%s,%s) realLen(%d)", szMainType, szSubType, realLen)
  if not realLen then
    ErrPrintL("save item to mem fail:(%s,%s) ", szMainType, szSubType)
    return false
  end
  ret = tlFesDev.FesDownData({
    addr = 0,
    len = realLen,
    dataBuf = data_buf,
    bufOffset = 0,
    uiPromptOnce = 0,
    uiCbProgress = false,
    totalUnPromptLenInPkt = 0,
    uiCurrent = 0,
    data_tag = SUNXI_EFEX_TAG.sunxi_efex_boot0_tag,
    media_index = FES_MEDIA_INDEX.DRAM
  })
  if not ret then
    ErrPrintL("Fail to Fes Down Data")
    data_buf.Free()
    return false
  end
  ret = fes_verify_transfer_status({
    tlFesDev = tlFesDev,
    tag = SUNXI_EFEX_TAG.sunxi_efex_boot0_tag
  })
  if not ret then
    ErrPrintL("Verify status error")
    return false
  end
  MsgPrintL("down boot0 success!!!")
  return true
end

function entry_fel2fes(tbl_felPara)
  print("--------------entry-fel2fes Called-----------")
  PrintTbl(tbl_felPara)
  MsgPrintL("Hi, I'm fel, dev=%s", tbl_felPara.felDevName)
  if "table" ~= type(toolsInitPara) then
    ErrPrintL("table~= type(toolsInitPara)(%s)", type(toolsInitPara))
    return false
  end
  local image = toolsInitPara.image
  local tlFelDev = Tools_Fex_Dev(tbl_felPara.felDevName)
  if not tlFelDev then
    ErrPrintL("Fail to open fel dev [%s]", tbl_felPara.felDevName)
    return nil
  end
  local tlFelBuf = Tools_Buffer(Cfg.Tools_CFG.IMG_BUF_LEN)
  if not tlFelBuf then
    ErrPrintL("Fail to alloc buffer for image item.")
    tlFelDev.Close()
    return false
  end
  MsgPrintL("To down and Run fes1-1")
  ret = fel_down_and_run_fes1({
    szMainType = IMG_ITEM.main.FES,
    szSubType = IMG_ITEM.sub.FES.fes1_1,
    image = image,
    tlFelBuf = tlFelBuf,
    tlFelDev = tlFelDev
  })
  if not ret then
    ErrPrintL("fes1-1 failed")
    tlFelDev.Close()
    tlFelBuf.Free()
    return false
  end
  MsgPrintL("To down and Run uboot")
  ret = fel_down_and_run_uboot({
    szMainType = IMG_ITEM.main.MP_FILE,
    szSubType = IMG_ITEM.sub.MP_FILE.uboot,
    image = image,
    tlFelBuf = tlFelBuf,
    tlFelDev = tlFelDev
  })
  if not ret then
    ErrPrintL("uboot down and run failed")
    tlFelDev.Close()
    tlFelBuf.Free()
    return false
  end
  tlFelBuf.Free()
  tlFelDev.Close()
  print("---fun end---")
  return true
end

local function get_file_size(filename)
  if "string" ~= type(filename) then
    ErrPrintL("file path type error: %s", type(filename))
    return nil
  end
  local file = io.open(filename, "rb")
  if not file then
    ErrPrintL("open file  error: %s", type(filename))
    return false
  end
  return file:seek("end")
end

local function upload_system(para)
  local filepath = para.basefile
  local verifyfile = para.verifyfile
  local tlFesDev = para.tlFesDev
  local data_buf = para.data_buf
  local flash_add = para.flash_add
  if not (filepath and verifyfile and tlFesDev and data_buf) or not flash_add then
    ErrPrintL("para error")
  end
  local imgFile = Tools_File(filepath, "rb+")
  if not imgFile then
    print("tools_file error")
    return nil
  end
  local tlFelBuf = Tools_Buffer(2097152)
  if not tlFelBuf then
    ErrPrintL("Fail to alloc buffer for image item.")
    tlFelDev.Close()
    return false
  end
  local SEEK_SET, SEEK_CUR, SEEK_END = 0, 1, 2
  local file_size = get_file_size(filepath)
  local v_file = Tools_File(verifyfile, "wb+")
  if not v_file then
    ErrPrintL("Fail to open file %s to write", verifyfile)
    return false
  end
  local readed = 0
  local header_buf = tlFelBuf
  imgFile.Read(header_buf.BuffShift(0), 28)
  v_file.Write(header_buf.BuffShift(0), 28)
  local sparse_magic = header_buf.GetMemVal2Int32(0)
  local sparse_major_ver = header_buf.GetMemVal2Int16(4)
  local sparse_head_size = header_buf.GetMemVal2Int16(8)
  local chunk_head_size = header_buf.GetMemVal2Int16(10)
  local blk_size = header_buf.GetMemVal2Int16(12)
  local total_blk = header_buf.GetMemVal2Int16(16)
  local total_chunk = header_buf.GetMemVal2Int16(20)
  MsgPrintL("magic = %x", sparse_magic)
  MsgPrintL("blk_size = %x", blk_size)
  MsgPrintL("total_chunk = %x", total_blk)
  local chunk_cnt = 0
  local read_len = 128
  local flash_add_tmp = flash_add
  repeat
    imgFile.Read(header_buf.BuffShift(0), 12)
    v_file.Write(header_buf.BuffShift(0), 12)
    local chunk_type = header_buf.GetMemVal2Int16(0)
    local chunk_sz = header_buf.GetMemVal2Int32(4)
    local total_sz = header_buf.GetMemVal2Int32(8)
    local ofs = 0
    local chunk_data_sz = chunk_sz * blk_size
    if chunk_data_sz ~= chunk_data_sz / 512 * 512 then
      ErrPrintL("chunk data size is not sector align")
      break
    end
    if chunk_type == SPARSE_INFO.chunk_type_raw then
      MsgPrintL("chunk type raw")
      if total_sz ~= chunk_sz * blk_size + 12 then
        ErrPrintL("bad chunk size")
        break
      end
      local chunk_data_len = chunk_data_sz / 512
      while read_len < chunk_data_len do
        ret = tlFesDev.FesUpData({
          addr = flash_add_tmp,
          len = read_len * 512,
          dataBuf = data_buf,
          bufOffset = 0,
          uiPromptOnce = 0,
          uiCbProgress = false,
          totalUnPromptLenInPkt = 0,
          uiCurrent = 0,
          data_tag = SUNXI_EFEX_TAG.sunxi_efex_flash_tag,
          media_index = FES_MEDIA_INDEX.FLASH_LOG
        })
        if not ret then
          ErrPrintL("Fail to Fes Up  Data")
          return false
        end
        if not v_file.Write(data_buf.BuffShift(0), read_len * 512) then
          ErrPrintL("Failed to write to file")
          return false
        end
        flash_add_tmp = flash_add_tmp + read_len
        chunk_data_len = chunk_data_len - read_len
      end
      if 0 < chunk_data_len then
        ret = tlFesDev.FesUpData({
          addr = flash_add_tmp,
          len = chunk_data_len * 512,
          dataBuf = data_buf,
          bufOffset = 0,
          uiPromptOnce = 0,
          uiCbProgress = false,
          totalUnPromptLenInPkt = 0,
          uiCurrent = 0,
          data_tag = SUNXI_EFEX_TAG.sunxi_efex_flash_tag,
          media_index = FES_MEDIA_INDEX.FLASH_LOG
        })
        if not ret then
          ErrPrintL("Fail to Fes Up  Data")
          return false
        end
        if not v_file.Write(data_buf.BuffShift(0), chunk_data_len * 512) then
          ErrPrintL("Failed to write to file")
          return false
        end
        flash_add_tmp = flash_add_tmp + chunk_data_len
      end
    elseif chunk_type == SPARSE_INFO.chunk_type_null then
      MsgPrintL("chunk type null")
      if total_sz ~= 12 then
        ErrPrintL("bad chunk size")
        break
      end
      flash_add_tmp = flash_add_tmp + chunk_data_sz / 512
    else
      MsgPrintL("unknow chunk type")
      break
    end
    ofs = total_sz - 12
    imgFile.Seek(ofs, SEEK_CUR)
    chunk_cnt = chunk_cnt + 1
  until total_chunk <= chunk_cnt
  v_file.Close()
  imgFile.Close()
  tlFelBuf.Free()
  if chunk_cnt == total_chunk then
    MsgPrintL("sparse ok: %d chunks", total_chunk)
  end
  return true
end

local function fes_verify_img(para)
  if "table" ~= type(para.tlFesDev) or "table" ~= type(para.tlBufImg) then
    ErrPrintL("arguments check error: table, table but(%s,%s)", type(para.tlFesDev), type(para.tlBufImg))
    return nil
  end
  local tlFesDev, data_buf = para.tlFesDev, para.tlBufImg
  local mbr_buf = para.mbr_buf
  local mbr_size, mbr_copy_num = 16384, 4
  local buf_size = mbr_size * mbr_copy_num
  local ret = tlFesDev.Fex_SetFlashOnOff({flash_on = 1, flash_type = 0})
  if not ret then
    ErrPrintL("open flash fail")
    return false
  end
  ret = tlFesDev.FesUpData({
    addr = 0,
    len = 65536,
    dataBuf = mbr_buf,
    bufOffset = 0,
    uiPromptOnce = 0,
    uiCbProgress = false,
    totalUnPromptLenInPkt = 0,
    uiCurrent = 0,
    data_tag = SUNXI_EFEX_TAG.sunxi_efex_flash_tag,
    media_index = FES_MEDIA_INDEX.FLASH_LOG
  })
  if not ret then
    ErrPrintL("Fail to Fes Up  Data")
    return false
  end
  local flag = false
  local ok_copy = 0
  for i = 0, mbr_copy_num - 1 do
    local cal_crc = mbr_buf.CalCrc32({
      pos = i * mbr_size + 4,
      nBytes = mbr_size - 4
    })
    local file_crc = mbr_buf.GetMemVal2Int32(i * mbr_size)
    MsgPrintL("file_cre = %x cal-crc = %x", file_crc, cal_crc)
    if cal_crc == file_crc then
      flag = true
      ok_copy = i
      break
    end
  end
  if not flag then
    ErrPrintL("mbr check crc error")
    return false
  end
  local basefilepath = "/home/user/lichee/tools/pack/out_android/"
  local boot_file = basefilepath .. "boot.img"
  local recovery_file = basefilepath .. "recovery.img"
  local system_file = basefilepath .. "system.img"
  local boot_size = get_file_size(boot_file)
  local recovery_size = get_file_size(recovery_file)
  local system_size = get_file_size(system_file)
  if not (boot_size and recovery_size) or not system_size then
    ErrPrintL("get file size fail")
    return false
  end
  local base_file_tl = {}
  base_file_tl.boot = boot_size / 512
  base_file_tl.recovery = recovery_size / 512
  base_file_tl.system = system_size / 512
  base_file_tl["boot-resource"] = 0
  base_file_tl.env = 0
  base_file_tl.data = 0
  base_file_tl.misc = 0
  base_file_tl.cache = 0
  base_file_tl.databk = 0
  base_file_tl.UDISK = 0
  MsgPrintL("boot size = %d, recover size = %d system_size = %d", boot_size, recovery_size, system_size)
  local filepath = "/home/user/imgdata/"
  local read_len = 128
  local partStSz = 128
  local partStOfs = 32
  local keydataOfs = 52
  local partNum = mbr_buf.GetMemVal2Int32(ok_copy * mbr_size + 24)
  for i = 0, partNum do
    local partName = mbr_buf.GetMemVal2Chars({
      pos = ok_copy * mbr_size + partStOfs + partStSz * i + 32,
      nLen = 16
    })
    local addrhi = mbr_buf.GetMemVal2Int32(ok_copy * mbr_size + partStOfs + partStSz * i + 0)
    local addrlo = mbr_buf.GetMemVal2Int32(ok_copy * mbr_size + partStOfs + partStSz * i + 4)
    local lenhi = mbr_buf.GetMemVal2Int32(ok_copy * mbr_size + partStOfs + partStSz * i + 8)
    local lenlo = mbr_buf.GetMemVal2Int32(ok_copy * mbr_size + partStOfs + partStSz * i + 12)
    MsgPrintL("name = %s, addrlo = %x lenlo = %x", partName, addrlo, lenlo)
    local file_name = filepath .. partName
    local len = base_file_tl[partName]
    local addr = addrlo
    if partName == "system" then
      ret = upload_system({
        basefile = system_file,
        verifyfile = file_name,
        flash_add = addrlo,
        tlFesDev = tlFesDev,
        data_buf = data_buf
      })
      if not ret then
        ErrPrintL("up load system error")
        return ret
      end
    elseif partName == "boot" or partName == "recovery" then
      local tl_file = Tools_File(file_name, "wb+")
      if not tl_file then
        ErrPrintL("Fail to open file %s to write", file_name)
        return
      end
      while read_len < len do
        ret = tlFesDev.FesUpData({
          addr = addr,
          len = read_len * 512,
          dataBuf = data_buf,
          bufOffset = 0,
          uiPromptOnce = 0,
          uiCbProgress = false,
          totalUnPromptLenInPkt = 0,
          uiCurrent = 0,
          data_tag = SUNXI_EFEX_TAG.sunxi_efex_flash_tag,
          media_index = FES_MEDIA_INDEX.FLASH_LOG
        })
        if not ret then
          ErrPrintL("Fail to Fes Up  Data")
          return false
        end
        if not tl_file.Write(data_buf.BuffShift(0), read_len * 512) then
          ErrPrintL("Failed to write to file")
          return false
        end
        addr = addr + read_len
        len = len - read_len
      end
      if 0 < len then
        ret = tlFesDev.FesUpData({
          addr = addr,
          len = len * 512,
          dataBuf = data_buf,
          bufOffset = 0,
          uiPromptOnce = 0,
          uiCbProgress = false,
          totalUnPromptLenInPkt = 0,
          uiCurrent = 0,
          data_tag = SUNXI_EFEX_TAG.sunxi_efex_flash_tag,
          media_index = FES_MEDIA_INDEX.FLASH_LOG
        })
        if not ret then
          ErrPrintL("Fail to Fes Up  Data")
          return false
        end
        if not tl_file.Write(data_buf.BuffShift(0), len * 512) then
          ErrPrintL("Failed to write to file")
          return false
        end
      end
      tl_file.Close()
    end
  end
  ret = tlFesDev.Fex_SetFlashOnOff({flash_on = 0, flash_type = 0})
  if not ret then
    ErrPrintL("close flash fail")
    return false
  end
  local diffboot = os.execute("diff /home/user/lichee/tools/pack/out_android/boot.img  /home/user/imgdata/boot")
  local diffrecovery = os.execute("diff /home/user/lichee/tools/pack/out_android/recovery.img  /home/user/imgdata/recovery")
  local diffsystem = os.execute("diff /home/user/lichee/tools/pack/out_android/system.img  /home/user/imgdata/system")
  local logfile = io.open("/home/user/imgdata/log.txt", "a+")
  if logfile then
    logfile:write(os.date("%c\n", os.time()))
    logfile:write(diffboot)
    logfile:write(" ")
    logfile:write(diffrecovery)
    logfile:write(" ")
    logfile:write(diffsystem)
    logfile:write(" ")
    logfile:write("\n")
  end
  logfile:close()
  return true
end

function entry_fes_thread(tbl_fesPara)
  print("--------------entry fes_thread Called---------")
  PrintTbl(tbl_fesPara)
  MsgPrintL("enter FES--%s", tbl_fesPara.fesDevName)
  if "table" ~= type(tbl_fesPara) then
    ErrPrintL("table~= (%s)", type(tbl_fesPara))
    return nil
  end
  local fesDevName, deviceId, hubId = tbl_fesPara.fesDevName, tbl_fesPara.DeviceId, tbl_fesPara.hubId
  if "string" ~= type(fesDevName) or "number" ~= type(deviceId) or "number" ~= type(hubId) then
    ErrPrintL("string,number,number, but(%s,%s,%s)", type(fesDevName), type(deviceId), type(hubId))
    return false
  end
  local tlFesDev = Tools_Fex_Dev(tbl_fesPara.fesDevName)
  if not tlFesDev then
    ErrPrintL("Fail to open fes dev [%s]", tbl_fesPara.fesDevName)
    return nil
  end
  local image = toolsInitPara.image
  local tlBufImg = Tools_Buffer(Cfg.Tools_CFG.IMG_BUF_LEN)
  if not tlBufImg then
    ErrPrintL("Fail to alloc buffer")
    tlFesDev.Close()
    return false
  end
  local uiCallBack = Tools_UI({DevId = deviceId})
  if not uiCallBack then
    ErrPrintL("Fail to get ui callBack fun")
    tlBufImg.Free()
    tlFesDev.Close()
    return false
  end
  if toolsInitPara.Mode == WORK_MODE_UPDATE then
    ret = fes_down_erase_flag({
      tlImg = image,
      tlFesDev = tlFesDev,
      tlBufImg = tlBufImg
    })
    if not ret then
      ErrPrintL("down erase flag fail")
      uiCallBack.PromptError({
        errId = 921,
        errMsg = "Fail to download erase flag"
      })
      tlBufImg.Free()
      tlFesDev.Close()
      return false
    end
  end
  uiCallBack.SendProgress({nPercents = 3})
  local ret, storage_type
  local mbr_part_keydata = {}
  ret = fes_down_mbr({
    tlImg = image,
    tlFesDev = tlFesDev,
    tlBufImg = tlBufImg,
    mbr_part_keydata = mbr_part_keydata
  })
  uiCallBack.SendProgress({nPercents = 4})
  if not ret then
    ErrPrintL("down mbr error")
    uiCallBack.PromptError({
      errId = 1024,
      errMsg = "Fail to download mbr"
    })
    tlBufImg.Free()
    tlFesDev.Close()
    return false
  end
  storage_type = fes_get_storage_type({tlFesDev = tlFesDev})
  local full_img_exist
  if storage_type == 3 then
    ret, full_img_exist = fes_down_full_image({
      tlImg = image,
      tlFesDev = tlFesDev,
      tlBufImg = tlBufImg,
      uiCallBack = uiCallBack,
      uiStepStart = 5,
      uiStepEnd = 95,
      mbr_part_key = mbr_part_keydata
    })
    if not full_img_exist then
      MsgPrintL("---full image not exist-----")
    elseif not ret then
      ErrPrintL("down full image error")
      tlBufImg.Free()
      tlFesDev.Close()
      return false
    else
      ErrPrintL("down full image success")
      tlBufImg.Free()
      tlFesDev.Close()
      return true
    end
  end
  ret = fes_down_partition({
    tlImg = image,
    tlFesDev = tlFesDev,
    tlBufImg = tlBufImg,
    uiCallBack = uiCallBack,
    uiStepStart = 5,
    uiStepEnd = 95,
    mbr_part_key = mbr_part_keydata
  })
  if not ret then
    ErrPrintL("down partition error")
    uiCallBack.PromptError({
      errId = 1025,
      errMsg = "Fail to download partition"
    })
    tlBufImg.Free()
    tlFesDev.Close()
    return false
  end
  uiCallBack.SendProgress({nPercents = 96})
  ret = fes_down_uboot({
    tlImg = image,
    tlFesDev = tlFesDev,
    tlBufImg = tlBufImg,
    storage_type
  })
  if not ret then
    ErrPrintL("down uboot error")
    uiCallBack.PromptError({
      errId = 1026,
      errMsg = "Fail to download uboot"
    })
    tlBufImg.Free()
    tlFesDev.Close()
    return false
  end
  uiCallBack.SendProgress({nPercents = 97})
  ret = fes_down_boot0({
    tlImg = image,
    tlFesDev = tlFesDev,
    tlBufImg = tlBufImg
  })
  if not ret then
    ErrPrintL("down boot0 error")
    uiCallBack.PromptError({
      errId = 1027,
      errMsg = "Fail to download boot0"
    })
    tlBufImg.Free()
    tlFesDev.Close()
    return false
  end
  uiCallBack.SendProgress({nPercents = 98})
  ret = tlFesDev.Fex_SetToolMode({tool_mode = 8, next_mode = 0})
  if not ret then
    ErrPrintL("set next work mode fail!!!")
    return false
  end
  tlBufImg.Free()
  tlFesDev.Close()
  uiCallBack.SendFesEnd({})
  MsgPrintL("---fun end-----")
  Exit()
  return true
end
