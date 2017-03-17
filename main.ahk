;In-raid Tier Script for DotD
;
;Controls:
;F1 = Start/stop script
;F2 = Record new entry (locked in release version)
;F3 = [reserved]
;F4 = Exit application

#NoEnv
#SingleInstance force
SendMode Input
SetWorkingDir %A_ScriptDir%
Thread,interrupt,0
#KeyHistory 0
#MaxThreads 255
#MaxMem 4095
#MaxThreadsBuffer On
#MaxHotkeysPerInterval 99000000
#HotkeyInterval 99000000
Process, Priority, , R
SetTitleMatchMode fast
SetKeyDelay, -1, -1, -1
SetMouseDelay, -1
SetWinDelay, -1
SetControlDelay, -1
#Persistent
;Variable notes:
;Fields are parsed from CSV files.
;field: rgb1   rgb2   rgb3   "raidname" "Tier strings"
;main : a%i%_1 a%i%_2 a%i%_3 a%i%_n     a%i%_s
;found:                      m%i%_n     m%i%_s
;Indices found in a_len and m_len
;Position notes:
;initial calibration - 348,124
;samp 1 - 400,280 --> +52,+156
;samp 2 - 530,340 --> +182,+216
;samp 3 - 480,670 -->  +132,546
;namefield check:  280,192 --> -68,+68
;lootbutton check: 100,730 -->  -248,+606
;resource change area : 405,735 --> +57,+611
;
;For sources, use insurgi's or mutik's tables.
;For really old raids, use Leon's
;---------------------
c1 = 0
c2 = 0
c3 = 0
lootpix = 0
curraid:="" 
tooltips = 0
test= null
gui_opened = 0
ifexist,DEBUG
  debug_mode = 1
else
  debug_mode = 0
timer_state = 0
anchor_x = 0
anchor_y = 0
anchor_f = "home.bmp"
a_len = 0
m_len = 0
;tool|tray|both
msg_display_type = tool
;Loading index file, or creating a new one if it does not exist.
if FileExist("raiddb.dat") {
  ToolTip,Reading raid database...,0,0
  Loop,READ,raiddb.dat
  {
    a_len++
    a%a_len%_c := 0  ;compatibility with older database
    Loop,PARSE,A_LoopReadLine,CSV
    {
      if (A_Index=1)
        a%a_len%_1:=A_LoopField
      if (A_Index=2)
        a%a_len%_2:=A_LoopField
      if (A_Index=3)
        a%a_len%_3:=A_LoopField
      if (A_Index=4)
        a%a_len%_n:=A_LoopField
      if (A_Index=5)
        a%a_len%_s:=A_LoopField
      if (A_Index=6)
        a%a_len%_c:=A_LoopField
    }
  }
  ToolTip
}
;---------------------
OnExit,SystemCleanup
Return
;###############################################################################

F1::
timer_state := !timer_state
if (timer_state) {
  SetTimer,raidcheck,500
  ShowMsg("DotD in-raid tier script is`nnow monitoring the game.")
} else {
  SetTimer,raidcheck,Off
  ShowMsg("DotD in-raid tier script`nhas been paused.")
  remove_tooltips()
  curraid:="" 
}
Return
;---------------------------
F2::
if (!debug_mode)
  Return
AddNewEntry()
Return
;---------------------------
F3::
if (!debug_mode)
  return
FindAnchor(x,y)
;calib 348,124
ToolTip,CALIB %x%`,%y%,0,0,4
c1:=(x+52)
c2:=(y+156)
ToolTip,LOC1,%c1%,%c2%,1
c1:=(x+182)
c2:=(y+216)
ToolTip,LOC2,%c1%,%c2%,2
c1:=(x+132)
c2:=(y+546)
ToolTip,LOC3,%c1%,%c2%,3
tooltips=3
;100,730 -> -248,606
c1:=(x-248)
c2:=(y+606)
PixelGetColor,rgbl,%c1%,%c2%
ToolTip,LOOTBOX:%rgbl%,0,20,5
Return
;---------------------------
F4::
ExitApp

;*******************************************************************************
raidcheck:
FindMatch()
if (!m_len)
{
  remove_tooltips()
  curraid:=""
  return
}
if (m1_n=curraid and curraid!="")
  return
if (curraid!=m1_n)
  remove_tooltips()
curraid:=m1_n
  ;initial calibration - 348,124
cx := anchor_x-294
cy := anchor_y+130
Loop,%m_len%
{
  tooltips++
  s := m%A_Index%_n " : " m%A_Index%_s
  Tooltip,%s%,%cx%,%cy%,%tooltips%
  cy+=30
}

Return
;*******************************************************************************

removetooltip:
Tooltip,,,,20
Return
remove_tooltips()
{
  Global tooltips
  Loop,%tooltips%
    Tooltip,,,,%A_Index%
  tooltips = 0
  return 0
}

GuiClose:
gui_opened := 0
Gui,destroy
Return

FUNC_DATABASE:
Gui,Submit,NoHide
fill_out_display(EDIT_DATABASE)
return

FUNC_MATCHING:
Gui,Submit,NoHide
fill_out_display(EDIT_MATCHING)
return

EDIT_ACCEPT:
;using: EDIT_RAIDNAME, EDIT_RAIDDATA
Gui,Submit,NoHide
;Do not accept an entry with an empty raid name.
if (EDIT_RAIDNAME="")
  return
;Add empty entry to database if RGB and NAME does not match any entries.
s=0 
Loop,%a_len%
{
  a := A_Index
  if (c1=a%a%_1 && c2=a%a%_2 && c3=a%a%_3 && EDIT_RAIDNAME=a%a%_n)
  {
    s=1
    break
  }
}
if (!s)
{
    a_len++
    a%a_len%_1:=c1
    a%a_len%_2:=c2
    a%a_len%_3:=c3
    a%a_len%_n:=EDIT_RAIDNAME
    if (lootpix=0x795C2F)
      a%a_len%_c=0
    else
      a%a_len%_c=1
}
;update all entries marked with EDIT_RAIDNAME with contents of EDIT_RAIDDATA
;Ensure that a blank entry in raiddata does not foul up the database.
;because it will for some reason.
If (EDIT_RAIDDATA="")
  s:=" "
else
  s:=EDIT_RAIDDATA
Loop,%a_len%
  if (a%A_Index%_n=EDIT_RAIDNAME)
    a%A_Index%_s := s

goto GuiClose

EDIT_CANCEL:
goto GuiClose

;===============================================================================
AddNewEntry()
{
  Global
  Local matches,x,y,a,b,c,d,e,f,g
  if (gui_opened)
    return
  matches := FindMatch()
  if (GetGamePixels(c1,c2,c3))
    return 1
  a:=(anchor_x-248)
  b:=(anchor_y+606)
  PixelGetColor,lootpix,%a%,%b%
  ;Gui construc
  Gui,Add,Text,x5 y5 w190 h15 Center,Raid Name
  Gui,Add,Edit,x5 y25 w190 h23 vEDIT_RAIDNAME
  Gui,Add,Text,x5 y55 w190 h15 Center,Raid Tier Data
  Gui,Add,Edit,x5 y75 w190 r6 vEDIT_RAIDDATA
  Gui,Add,Text,x5 y175 w190 h15 Center,Raid graphics also shared with
  Gui,Add,ListBox,x5 y195 w190 r7 gFUNC_MATCHING vEDIT_MATCHING,
  Gui,Add,Text,x200 y5 w190 h15 Center,Raid Database
  Gui,Add,ListBox,x200 y25 w190 r17 gFUNC_DATABASE vEDIT_DATABASE,
  Gui,Add,Button,x200 y260 w105 h30 gEDIT_ACCEPT,Add/Update
  Gui,Add,Button,x320 y260 w70 h30 gEDIT_CANCEL Default,Cancel
  ;populate edit database
  s := ""
  Loop,%a_len%
  {
    a := a%A_Index%_n
    b = 0
    Loop,PARSE,s,|
    {
      if (a=A_LoopField)
      {
        b=1
        break
      }
    }
    if (!b)
      s .= a "|"
  }
  GuiControl,,EDIT_DATABASE,%s%
  ;populate alike-list
  s := ""
  Loop,%a_len%
  {
    if (a%A_Index%_1=c1 && a%A_Index%_2=c2 && a%A_Index%_3=c3)
      s .= a%A_Index%_n "|"
  }
  GuiControl,,EDIT_MATCHING,%s%
  ;setup main container window and render it
  FindAnchor(x,y)
  WinGetPos,a,b,,,A
  x+=470+a
  y+=b
  Gui,show,w400 h300 x%x% y%y%,DotD In-Raid Tier Editor
  Gui,+AlwaysOnTop
  gui_opened := 1
  while (gui_opened)
    Sleep 1000
  return
}
;----------------------------------------------------------------------------
FindAnchor(Byref x, Byref y)
{
  Global anchor_x,anchor_y,anchor_f
  cwd:=A_ScriptDir
  ImageSearch,x1,y1,(anchor_x-1),(anchor_y-1),(anchor_x+40),(anchor_y+40),home.bmp
  if (ErrorLevel)
  {
    WinGetPos,wx,wy,ww,wh,A
    ImageSearch,x2,y2,0,0,ww,wh,home.bmp
    if (ErrorLevel)
      return 1
    x := x2
    y := y2
  } else {
    x := x1
    y := y1
  }
  anchor_x := x
  anchor_y := y
  return 0
}

;returns number of entries that matched the given three point color codes
FindMatch()
{
  global
  local rgb1,rgb2,rgb3,ltpix,a,b,c,r
  m_len:=0
  if (GetGamePixels(rgb1,rgb2,rgb3))
    return 0
  a:=(anchor_x-248)
  b:=(anchor_y+606)
  PixelGetColor,ltpix,%a%,%b%
  ;print("src [" a_index "] (" rgb1 "," rgb2 "," rgb3 ")")
  Loop,%a_len%
  {
    ;print("chk[" a_index "] (" a%a_index%_1 "," a%a_index%_2 "," a%a_index%_3 ")")
    if (rgb1=a%a_index%_1 && rgb2=a%a_index%_2 && rgb3=a%a_index%_3)
      if ((ltpix=0x795C2F && (!a%a_index%_c)) || a%a_index%_c)
      {
        m_len++
        m%m_len%_n := a%a_index%_n
        m%m_len%_s := a%a_index%_s
      }
  }
  return m_len
}

GetGamePixels(ByRef rgb1,ByRef rgb2, ByRef rgb3)
{
  if (FindAnchor(x,y))
    return 1
  PixelGetColor rgbt,(x+57),(y+611)  ;ref: 0x275A61
  if (rgbt!=0x275A61)
    return 1
  PixelGetColor rgb1,(x+52),(y+156)
  PixelGetColor rgb2,(x+182),(y+216)
  PixelGetColor rgb3,(x+132),(y+546)
  return 0
}

fill_out_display(v)
{
  Global
  Local s
  s := search_db_by_name(v)
  if (s!="")
  {
    GuiControl,,EDIT_RAIDNAME,%v%
    GuiControl,,EDIT_RAIDDATA,%s%
  }
  return
}

search_db_by_name(v)
{
  Global
  Loop,%a_len%
    if (a%A_Index%_n=v)
      return a%A_Index%_s
  Return ""
}

isGameWinActive()
{
  return WinActive("Dawn of the Dragons")
}

ShowMsg(ByRef string,disptype=0)
{
  global msg_display_type
  if (!disptype)
    disptype:=msg_display_type
  if (disptype="both" or disptype="tool")
  {
    ToolTip,%string%,0,0,20
    SetTimer,removetooltip,-2500
  }
  if (disptype="both" or disptype="tray")
  {
    TrayTip,In-Raid DotD Notice,%string%
  }
  
}

print(str)
{
  OutputDebug,%str%
}
;===============================================================================
SystemCleanup:
if (!debug_mode)
  ExitApp
;in debug mode, allow writeback to database
IfExist,raiddb.dat
  FileDelete,raiddb.dat
Loop,%a_len%
{
  s := a%A_Index%_1 "," a%A_Index%_2 "," a%A_Index%_3 ","
  s .= """" a%A_Index%_n ""","
  s .= """" a%A_Index%_s ""","
  s .= a%A_Index%_c "`n"
  FileAppend,%s%,raiddb.dat
}
ExitApp


