require("regbasefun")
require("regdecode")
DEBUG_FLAG = 0
HEAD_ID = 1
TABLE_ID = 2
DATA_ID = 3
IF_CNT = 3
MAX_KEY_SIZE = 32
IMAGE_HEAD_SIZE = 96
IMAGE_HANDLE_SIZE = 136
IMAGE_ITEM_SIZE = 1024
ITEM_HANDLE_SIZE = 12
ENCODE_LEN = 16
SIZE_32K = 32768
g_bEncypt = 1
Img_Version = 100
Item_OffList = nil
g_hDecHead = nil
g_hDecTab = nil
g_hDecData = nil
g_DecIF = {
  g_hDecHead,
  g_hDecTab,
  g_hDecData
}
g_hImageHandle = {
  fp = nil,
  ImageHead = nil,
  ItemTab = nil,
  rc_if_decode = g_DecIF
}
ITEM_PHOENIX_TOOLS = "PXTOOLS "

function DebugPrint(str)
  if DEBUG_FLAG == 1 then
    print(str)
    DebugTrace("IMGDec Debug:" .. str .. "\n")
  end
end

function mprint(str)
  if DEBUG_FLAG == 1 then
    print(str)
    DebugTrace("IMGDec Debug:" .. str .. "\n")
  end
end

Img_Head64 = {
  I_H_MAGIC = 0,
  I_H_VERSION = 8,
  I_H_SIZE = 12,
  I_H_ATTR = 16,
  I_H_IMG_VERSION = 20,
  I_H_LELO = 24,
  I_H_LENHI = 28,
  I_H_ALIGN = 32,
  I_H_PID = 36,
  I_H_VID = 40,
  I_H_HARDAREID = 44,
  I_H_FIRMWAREID = 48,
  I_H_ITEMATTR = 52,
  I_H_ITEMSIZE = 56,
  I_H_ITEMCNT = 60,
  I_H_ITEMOFFSET = 64,
  I_H_IMAGEATTR = 68,
  I_H_APPENDISZE = 72,
  I_H_APPENDOFFSETLO = 76,
  I_H_APPENDOFFSETHI = 80,
  I_H_RESIVER = 84
}
Img_Head32 = {
  I_H_MAGIC = 0,
  I_H_VERSION = 8,
  I_H_SIZE = 12,
  I_H_ATTR = 16,
  I_H_IMG_VERSION = 20,
  I_H_LENLO = 24,
  I_H_LENHI = 0,
  I_H_ALIGN = 28,
  I_H_PID = 32,
  I_H_VID = 36,
  I_H_HARDAREID = 40,
  I_H_FIRMWAREID = 44,
  I_H_ITEMATTR = 48,
  I_H_ITEMSIZE = 52,
  I_H_ITEMCNT = 56,
  I_H_ITEMOFFSET = 60,
  I_H_IMAGEATTR = 64,
  I_H_APPENDISZE = 68,
  I_H_APPENDOFFSETLO = 72,
  I_H_APPENDOFFSETHI = 0
}
Img_Item32 = {
  I_T_VERSION = 0,
  I_T_SIZE = 4,
  I_T_MAINTYPE = 8,
  I_T_SUBTYPE = 16,
  I_T_ATTR = 32,
  I_T_DATALENLO = 36,
  I_T_FILELENLO = 40,
  I_T_OFFSETLO = 44,
  I_T_CHECKSUM = 48,
  I_T_NAME = 52,
  I_T_RES = 308
}
Img_Item64 = {
  I_T_SIZE = 4,
  I_T_MAINTYPE = 8,
  I_T_SUBTYPE = 16,
  I_T_ATTR = 32,
  I_T_NAME = 36,
  I_T_DATALENLO = 292,
  I_T_DATALENHI = 296,
  I_T_FILELENLO = 300,
  I_T_FILELENHI = 304,
  I_T_OFFSETLO = 308,
  I_T_OFFSETHI = 312,
  I_T_ENCYRPTID = 316,
  I_T_CHECKSUM = 380,
  I_T_RES = 384
}

function Img_Open(szImageFile)
  local ImageHead = MallocBuffer(IMAGE_HEAD_SIZE)
  local seed = {
    "69",
    "6d",
    "67"
  }
  local key_buff = "00000000000000000000000000000000"
  local key_len = MAX_KEY_SIZE
  local pTmpBuffer = MallocBuffer(key_len)
  for i = 0, IF_CNT - 1 do
    Memset(pTmpBuffer, i, key_len)
    SetMemValue(pTmpBuffer, key_len - 1, tostring(seed[i + 1]))
    key_buff = pTmpBuffer
    g_DecIF[i + 1] = Dec_Initial(key_buff, key_len)
    if nil == g_DecIF[i + 1] then
      free(pImage)
      return nil
    end
  end
  FreeBuffer(pTmpBuffer)
  local pImage = g_hImageHandle
  pImage.fp = LFopen(szImageFile, 0)
  DebugPrint(szImageFile)
  if nil == pImage.fp then
    return nil
  end
  local readRet = LFread(pImage.fp, ImageHead, IMAGE_HEAD_SIZE)
  DebugPrint("Read head return " .. readRet .. "\n")
  pImage.ImageHead = MallocBuffer(IMAGE_HEAD_SIZE)
  local lMagicBuff = MallocBuffer(9)
  CharsToBuffer(lMagicBuff, "IMAGEWTY")
  TraceBuffer(ImageHead, 32)
  if Memcmp(ImageHead, lMagicBuff, 8) == 0 then
    g_bEncypt = 0
  else
    g_bEncypt = 1
  end
  DebugPrint("g_bEncypt = " .. g_bEncypt .. "\n")
  if g_bEncypt == 1 then
    for i = 0, IMAGE_HEAD_SIZE - ENCODE_LEN, ENCODE_LEN do
      DebugTrace("pIn pOut:")
      local pIn = GetBuffer(ImageHead, i)
      local pOut = GetBuffer(pImage.ImageHead, i)
      Dec_Decode(pImage.rc_if_decode[HEAD_ID], pIn, pOut)
    end
  else
    Memcpy(pImage.ImageHead, ImageHead, IMAGE_HEAD_SIZE)
  end
  FreeBuffer(ImageHead)
  CharsToBuffer(lMagicBuff, "IMAGEWTY")
  local ncmpRet = Memcmp(pImage.ImageHead, lMagicBuff, 8)
  if ncmpRet ~= 0 then
    LFclose(pImage.fp)
    FreeBuffer(lMagicBuff)
    return nil
  end
  Img_Version = GetInt32FrmMem(pImage.ImageHead, Img_Head32.I_H_VERSION)
  local nIitemCnt = GetInt32FrmMem(pImage.ImageHead, Img_Head32.I_H_ITEMCNT)
  local ItemTableSize = nIitemCnt * IMAGE_ITEM_SIZE
  pImage.ItemTable = MallocBuffer(ItemTableSize)
  if nil == pImage.ItemTable then
    LFclose(pImage.fp)
    return nil
  end
  ItemTableBuf = MallocBuffer(ItemTableSize)
  if nil == ItemTableBuf then
    FLclose(pImage.fp)
    return nil
  end
  if Img_Version == 256 then
    LFseek(pImage.fp, GetInt32FrmMem(pImage.ImageHead, Img_Head32.I_H_ITEMOFFSET), 0, 0)
  elseif Img_Version >= 768 then
    LFseek(pImage.fp, GetInt32FrmMem(pImage.ImageHead, Img_Head64.I_H_ITEMOFFSET), 0, 0)
  else
    LFseek(pImage.fp, GetInt32FrmMem(pImage.ImageHead, Img_Head32.I_H_ITEMOFFSET), 0, 0)
  end
  LFread(pImage.fp, ItemTableBuf, ItemTableSize)
  local pItemTableDecode = pImage.ItemTable
  DebugTrace("ItemTableSize = " .. ItemTableSize)
  if g_bEncypt == 1 then
    for i = 0, ItemTableSize - ENCODE_LEN, ENCODE_LEN do
      local pin = GetBuffer(ItemTableBuf, i)
      local pout = GetBuffer(pItemTableDecode, i)
      Dec_Decode(pImage.rc_if_decode[TABLE_ID], pin, pout)
    end
  else
    Memcpy(pItemTableDecode, ItemTableBuf, ItemTableSize)
  end
  FreeBuffer(ItemTableBuf)
  FreeBuffer(lMagicBuff)
  return pImage
end

function min(nValue1, nValue2)
  if nValue1 < nValue2 then
    return nValue1
  else
    return nValue2
  end
end

function Img_OpenItem32(hImage, szMainType, szSubType)
  local pImage = hImage
  local pItem, dwLen
  if nil == pImage or nil == szMainType or nil == szSubType then
    DebugPrint("Img_OpenItem Error!")
    return nil
  end
  pItem = {
    nIndex = 0,
    loPos = 0,
    hiPos = 0
  }
  pItem.index = INVALID_INDEX
  pItem.loPos = 0
  pItem.hiPos = 0
  DebugPrint("Img_OpenItem[" .. szMainType .. "][" .. szSubType .. "]\n")
  local itemCnt = GetInt32FrmMem(pImage.ImageHead, Img_Head32.I_H_ITEMCNT)
  for i = 0, itemCnt - 1 do
    local tmpTab = GetBuffer(pImage.ItemTable, i * IMAGE_ITEM_SIZE)
    local szTmpMainType = BufferToChars(tmpTab, Img_Item32.I_T_MAINTYPE, 8)
    local szTmpSubType = BufferToChars(tmpTab, Img_Item32.I_T_SUBTYPE, 16)
    if szMainType == szTmpMainType then
      if ITEM_PHOENIX_TOOLS == szMainType then
        pItem.index = i
        return pItem
      elseif szSubType == szTmpSubType then
        pItem.index = i
        return pItem
      end
    end
  end
  DebugPrint("Img_OpenItem: cannot find item " .. szMainType .. szSubType)
  return nil
end

function Img_OpenItem64(hImage, szMainType, szSubType)
  local pImage = hImage
  local pItem
  szMainType = string.upper(szMainType)
  szSubType = string.upper(szSubType)
  DebugPrint("Img_OpenItem now! \n" .. szMainType .. szSubType)
  local dwLen
  if nil == pImage or nil == szMainType or nil == szSubType then
    DebugPrint("Img_OpenItem Error!")
    return nil
  end
  pItem = {
    nIndex = 0,
    loPos = 0,
    hiPos = 0
  }
  pItem.index = INVALID_INDEX
  pItem.loPos = 0
  pItem.hiPos = 0
  local itemCnt = GetInt32FrmMem(pImage.ImageHead, Img_Head64.I_H_ITEMCNT)
  for i = 0, itemCnt - 1 do
    local tmpTab = GetBuffer(pImage.ItemTable, i * IMAGE_ITEM_SIZE)
    local szTmpMainType = BufferToChars(tmpTab, Img_Item64.I_T_MAINTYPE, 8)
    local szTmpSubType = BufferToChars(tmpTab, Img_Item64.I_T_SUBTYPE, 16)
    szTmpMainType = string.upper(szTmpMainType)
    szTmpSubType = string.upper(szTmpSubType)
    if szMainType == szTmpMainType then
      if ITEM_PHOENIX_TOOLS == szMainType then
        pItem.index = i
        return pItem
      elseif szSubType == szTmpSubType then
        pItem.index = i
        return pItem
      end
    end
  end
  DebugPrint("Img_OpenItem: cannot find item " .. szMainType .. szSubType)
  return nil
end

function Img_OpenItem(hImage, szMainType, szSubType)
  local pImage = hImage
  local pItem
  if Img_Version >= 768 then
    pItem = Img_OpenItem64(pImage, szMainType, szSubType)
  else
    pItem = Img_OpenItem32(pImage, szMainType, szSubType)
  end
  return pItem
end

function Img_GetItemSize(hImage, hItem)
  local pImage = hImage
  local pItem = hItem
  if nil == pItem then
    return 0
  end
  local nIndex = pItem.index
  local pTmpTab = GetBuffer(pImage.ItemTable, nIndex * IMAGE_ITEM_SIZE)
  local loPos = 0
  local hiPos = 0
  if Img_Version == 256 then
    loPos = GetInt32FrmMem(pTmpTab, Img_Item32.I_T_FILELENLO)
  elseif Img_Version >= 768 then
    loPos = GetInt32FrmMem(pTmpTab, Img_Item64.I_T_FILELENLO)
    hiPos = GetInt32FrmMem(pTmpTab, Img_Item64.I_T_FILELENHI)
  else
    loPos = GetInt32FrmMem(pTmpTab, Img_Item32.I_T_FILELENLO)
  end
  return loPos, hiPos
end

function __Img_ReadItemData(hImage, hItem, buffer, Length)
  local readlen = 0
  local pImage = hImage
  local pItem = hItem
  local buffer_encode = MallocBuffer(ENCODE_LEN)
  local pos = 0
  local posHi = 0
  local dwLen
  local pTmpTable = GetBuffer(pImage.ItemTabale, pItem.index * IMAGE_ITEM_SIZE)
  if nil == pImage or nil == pItem or nil == buffer or 0 == Length then
    return 0
  end
  local fileLen = 0
  local dataLen = 0
  local nOffset = 0
  local hifileLen = 0
  local hidataLen = 0
  local hinOffset = 0
  if Img_Version == 256 then
    fileLen = GetInt32FrmMem(pTmpTable, Img_Item32.I_T_FILELENLO)
    dataLen = GetInt32FrmMem(pTmpTable, Img_Item32.I_T_DATALENLO)
    nOffset = GetInt32FrmMem(pTmpTable, Img_Item32.I_T_OFFSETLO)
  elseif Img_Version >= 768 then
    fileLen = GetInt32FrmMem(pTmpTable, Img_Item64.I_T_FILELENLO)
    dataLen = GetInt32FrmMem(pTmpTable, Img_Item64.I_T_DATALENLO)
    nOffset = GetInt32FrmMem(pTmpTable, Img_Item64.I_T_OFFSETLO)
    hifileLen = GetInt32FrmMem(pTmpTable, Img_Item64.I_T_FILELENHI)
    hidataLen = GetInt32FrmMem(pTmpTable, Img_Item64.I_T_DATALENHI)
    hinOffset = GetInt32FrmMem(pTmpTable, Img_Item64.I_T_OFFSETHI)
  end
  local nCmpRet = CompareInt64(pItem.loPos, pItem.hiPos, loItemLen, HiItemLen)
  if 1 <= nCmpRet then
    return 0
  end
  local nLen = Length
  nLen = min(Length, dataLen - pItem.loPos)
  if pItem.loPos % ENCODE_LEN == 0 then
    pos, posHi = Int64Add(nOffset, nOffsetHi, pItem.loPos, pItem.hiPos)
    LFseek(pImage.fp, pos, posHi)
    while readlen < nLen do
      Memset(buffer_encode, 0, ENCODE_LEN)
      LFread(pImage.fp, buffer_encode, ENCODE_LEN)
      pin = buffer_encode
      pout = buffer
      pout = GetBuffer(pout, readlen)
      if g_bEncypt == 1 then
        Dec_Decode(pImage.rc_if_decode[DATA_ID], pin, pout)
      else
        Memcpy(pout, pin, ENCODE_LEN)
      end
      readlen = readlen + min(nLen - readlen, ENCODE_LEN)
    end
    pItem.loPos, pItem.hiPos = Int64Add(pItem.loPos, pItem.hiPos, readlen, 0)
    return readlen
  else
    pl = pItem.loPos
    ph = pItem.hiPos
    pl, ph = Int64Dec(pItem.loPos, pItem.hiPos, pItem.loPos % ENCODE_LEN, 0)
    pos, posHi = Int64Add(nOffset, hinOffset, pl, ph)
    LFseek(pImage.fp, pos, posHi)
    if 0 < nLen and nLen < ENCODE_LEN then
      local read = ENCODE_LEN - pItem.pos % ENCODE_LEN
      if Length <= read then
        read = ENCODE_LEN - pItem.pos % ENCODE_LEN
        Memset(buffer_encode, 0, ENCODE_LEN)
        LFread(pImage.fp, buffer_encode, ENCODE_LEN)
        pin = buffer_encode
        pout = buffer
        pout = GetBuffer(pout, readlen)
        if g_bEncypt == 1 then
          Dec_Decode(pImage.rc_if_decode[DATA_ID], pin, pout)
        else
          Memcpy(pout, pin, ENCODE_LEN)
        end
        readlen = nLen
        pItem.pos = pItem.pos + readlen
        return readlen
      else
        local read = ENCODE_LEN - pItem.pos % ENCODE_LEN
        Memset(buffer_encode, 0, ENCODE_LEN)
        LFread(pImage.fp, buffer_encode, ENCODE_LEN)
        pin = buffer_encode
        pout = buffer
        pout = GetBuffer(pout, readlen)
        if g_bEncypt == 1 then
          Dec_Decode(pImage.rc_if_decode[DATA_ID], pin, pout)
        else
          Memcpy(pout, pin, ENCODE_LEN)
        end
        readlen = readlen + read
        local Left_Length = nLen - read
        Memset(buffer_encode, 0, ENCODE_LEN)
        LFread(pImage.fp, buffer_encode, ENCODE_LEN)
        pin = buffer_encode
        pout = buffer
        pout = GetBuffer(pout, readlen)
        if g_bEncypt == 1 then
          Dec_Decode(pImage.rc_if_decode[DATA_ID], pin, pout)
        else
          Memcpy(pout, pin, ENCODE_LEN)
        end
        readlen = readlen + Left_Length
        pItem.loPos, pItem.hiPos = Int64Add(pItem.loPos, pItem.hiPos, readlen, 0)
        return readlen
      end
    elseif nLen >= ENCODE_LEN then
      local read = ENCODE_LEN - pItem.loPos % ENCODE_LEN
      Memset(buffer_encode, 0, ENCODE_LEN)
      LFread(pImage.fp, buffer_encode, ENCODE_LEN)
      pin = buffer_encode
      pout = buffer
      pout = GetBuffer(pout + readlen)
      if g_bEncypt == 1 then
        Dec_Decode(pImage.rc_if_decode[DATA_ID], pin, pout)
      else
        Memcpy(pout, pin, ENCODE_LEN)
      end
      readlen = readlen + read
      local Left_Length = Length - read
      local Left_readlen = 0
      while Left_Length > Left_readlen do
        Memset(buffer_encode, 0, ENCODE_LEN)
        LFread(pImage.fp, buffer_encode, ENCODE_LEN)
        pin = buffer_encode
        pout = buffer
        pout = GetBuffer(pout, readlen)
        if g_bEncypt == 1 then
          Dec_Decode(pImage.rc_if_decode[DATA_ID], pin, pout)
        else
          Memcpy(pout, pin, ENCODE_LEN)
        end
        Left_readlen = Left_readlen + min(Left_Length - Left_readlen, ENCODE_LEN)
      end
      readlen = readlen + Left_readlen
    end
    pItem.loPos, pItem.hiPos = Int64Add(pItem.loPos, pItem.hiPos, readlen, 0)
    return readlen
  end
end

function Img_ReadItemData(hImage, hItem, buffer, length)
  local readlen = 0
  pImage = hImage
  pItem = hItem
  buffer_encode = MallocBuffer(SIZE_32K)
  local this_read
  local pos = 0
  local posHi = 0
  local dwLen
  local pTmpItemTab = GetBuffer(pImage.ItemTable, pItem.index * IMAGE_ITEM_SIZE)
  local loItemLen = 0
  local HiItemLen = 0
  local loDataLen = 0
  local HiDataLen = 0
  if Img_Version == 256 then
    loItemLen = GetInt32FrmMem(pTmpItemTab, Img_Item32.I_T_DATALENLO)
    loDataLen = GetInt32FrmMem(pTmpItemTab, Img_Item32.I_T_FILELENLO)
  elseif Img_Version == 768 then
    loItemLen = GetInt32FrmMem(pTmpItemTab, Img_Item64.I_T_DATALENLO)
    loDataLen = GetInt32FrmMem(pTmpItemTab, Img_Item64.I_T_FILELENLO)
    HiItemLen = GetInt32FrmMem(pTmpItemTab, Img_Item64.I_T_DATALENHI)
    HiDataLen = GetInt32FrmMem(pTmpItemTab, Img_Item64.I_T_FILELENHI)
  end
  local nCmpRet = CompareInt64(pItem.loPos, pItem.hiPos, loItemLen, HiItemLen)
  if 1 <= nCmpRet then
    DebugTrace("Img_ReadItemData Error ")
    return nil
  end
  local nLeftLenLo = 0
  local nLeftLenHi = 0
  nLeftLenLo, nLeftLenHi = Int64Dec(loDataLen, HiDataLen, pItem.loPos, pItem.hiPos)
  local nTmpLen = min(length, nLeftLenLo)
  if nLeftLenHi ~= 0 then
    nTmpLen = length
  end
  length = nTmpLen
  local nOffsetLo = 0
  local nOffsetHi = 0
  if Img_Version == 256 then
    nOffsetLo = GetInt32FrmMem(pTmpItemTab, Img_Item32.I_T_OFFSETLO)
  elseif Img_Version == 768 then
    nOffsetLo = GetInt32FrmMem(pTmpItemTab, Img_Item64.I_T_OFFSETLO)
    nOffsetHi = GetInt32FrmMem(pTmpItemTab, Img_Item64.I_T_OFFSETHI)
  end
  if pItem.loPos % ENCODE_LEN == 0 then
    pos, posHi = Int64Add(nOffsetLo, nOffsetHi, pItem.loPos, pItem.hiPos)
    LFseek(pImage.fp, pos, posHi)
    readlen = 0
    while length > readlen do
      this_read = min(SIZE_32K, length - readlen)
      local n = (this_read + ENCODE_LEN - 1) / ENCODE_LEN
      n = math.floor(n)
      Memset(buffer_encode, 0, n * ENCODE_LEN)
      LFread(pImage.fp, buffer_encode, n * ENCODE_LEN)
      pin = buffer_encode
      pout = buffer
      pout = GetBuffer(pout, readlen)
      for i = 0, n - 1 do
        if g_bEncypt == 1 then
          Dec_Decode(pImage.rc_if_decode[DATA_ID], pin, pout)
        else
          Memcpy(pout, pin, ENCODE_LEN)
        end
        pin = GetBuffer(pin, ENCODE_LEN)
        pout = GetBuffer(pout, ENCODE_LEN)
      end
      readlen = readlen + this_read
    end
    pItem.loPos, pItem.hiPos = Int64Add(pItem.loPos, pItem.hiPos, readlen, 0)
    FreeBuffer(buffer_encode)
    return readlen
  else
    return __Img_ReadItemData(hImage, hItem, buffer, length)
  end
  return 0
end

function Img_CloseItem(hImage, hItem)
  local pItem = hItem
  if nil == pItem then
    return nil
  end
  FreeBuffer(pItem)
  pItem = nil
  return 0
end

function Img_Close(hImage)
  pImage = hImage
  DebugTrace("Closing image now! \n")
  if nil == pImage then
    return nil
  end
  if nil ~= pImage.fp then
    LFclose(pImage.fp)
    pImage.fp = nil
  end
  if nil ~= pImage.ImageHead then
    FreeBuffer(pImage.ImageHead)
  end
  if nil ~= pImage.ItemTable then
    FreeBuffer(pImage.ItemTable)
    pImage.ItemTable = nil
  end
  pImage = nil
  DebugTrace("Clos image OK! \n")
  return
end

function Img_DownItemToLocal(szImageFile, szMainName, szSubName, szLocFileName)
  local hImage = Img_Open(szImageFile)
  local nSize, nSizeHi = 0
  mprint(szImageFile)
  if hImage == nil then
    mprint("Error")
    return nil
  end
  local hItem = Img_OpenItem(hImage, szMainName, szSubName)
  if hItem ~= nil then
    nSize, nSizeHi = Img_GetItemSize(hImage, hItem)
    mprint("The Item Size is (" .. nSize .. ", " .. nSizeHi .. ")\n")
    local lpBuffer = MallocBuffer(nSize)
    local nRet = Img_ReadItemData(hImage, hItem, lpBuffer, nSize)
    Img_CloseItem(hImage, hItem)
    Img_Close(hImage)
    f = fopen(szLocFileName, "wb+")
    if f == nil then
      mprint("Open File " .. szImageFile .. " Error")
      return nil
    else
      mprint("Open File " .. szImageFile .. " OK")
    end
    local ptSize = nSize - 256
    for nPos = 0, nSize, 256 do
      local ptmp = GetBuffer(lpBuffer, nPos)
      if nPos > ptSize then
        fwrite(f, ptmp, nSize - nPos)
      else
        fwrite(f, ptmp, 256)
      end
    end
    fclose(f)
    FreeBuffer(lpBuffer)
  else
    mprint("Error open the file" .. szImageFile)
  end
end
