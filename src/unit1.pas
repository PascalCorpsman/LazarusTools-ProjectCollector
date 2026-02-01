(******************************************************************************)
(* Project_collector                                               ??.??.???? *)
(*                                                                            *)
(* Version     : 0.15                                                         *)
(*                                                                            *)
(* Author      : Uwe Schächterle (Corpsman)                                   *)
(*                                                                            *)
(* Support     : www.Corpsman.de                                              *)
(*                                                                            *)
(* Description : Copy all project files of a Lazarus Project into one single  *)
(*               folder.                                                      *)
(*                                                                            *)
(* License     : See the file license.md, located under:                      *)
(*  https://github.com/PascalCorpsman/Software_Licenses/blob/main/license.md  *)
(*  for details about the license.                                            *)
(*                                                                            *)
(*               It is not allowed to change or remove this text from any     *)
(*               source file of the project.                                  *)
(*                                                                            *)
(* Warranty    : There is no warranty, neither in correctness of the          *)
(*               implementation, nor anything other that could happen         *)
(*               or go wrong, use at your own risk.                           *)
(*                                                                            *)
(* Known Issues: none                                                         *)
(*                                                                            *)
(* History     : 0.01 - Initial version                                       *)
(*               0.02 - Unterdrücken Resolve fehler.                          *)
(*                      Einbauen Konsolensupport                              *)
(*               0.03 - Speichern der Recent lpi files                        *)
(*                      Umstellen auf Englische Texte                         *)
(*               0.04 - Bugfix Laden in Windows erstelltes .lpi auf Linux     *)
(*                        (Auflösen Relative Pfade hat nicht gestimmt)        *)
(*               0.05 - Bugfix Auflösen tieferer Relativer Pfade war Kaputt   *)
(*                        Aktivieren DragDrog von .lpi Dateien                *)
(*               0.06 - Bugfix, eine Unit die nicht Teil des Projektes ist,   *)
(*                        darf auch ihre .lfm nicht nachladen                 *)
(*               0.07 - Bugfix, Gemischte "/" und "\" in Absoluten und        *)
(*                        Relativen Pfaden wurden falsch aufgelöst            *)
(*               0.08 - Umstellen auf uDomXML                                 *)
(*               0.09 - Integration eines Doppelte Dateien Erkennens          *)
(*               0.10 - Form2.caption gesetzt.                                *)
(*               0.11 - Ini umgestellt auf locales User Verzeichnis           *)
(*               0.12 - Wenn die zu Kopierende Datei nicht im Relativen       *)
(*                        Verzeichnis, aber dafür im Lokalen ist, dann auch   *)
(*                        kopieren                                            *)
(*               0.13 - Default "ispartof" -> False                           *)
(*               0.14 - fix gui glitch on missing files                       *)
(*               0.15 -                                                       *)
(*                                                                            *)
(******************************************************************************)
Unit Unit1;

{$MODE objfpc}{$H+}

Interface

Uses
  Classes, SysUtils, FileUtil, LazFileUtils, LazUTF8, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, CheckLst, IniFiles;

Const
  Version = '0.15';

Type

  { TForm1 }

  TForm1 = Class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    CheckListBox1: TCheckListBox;
    ComboBox1: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    OpenDialog1: TOpenDialog;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    Procedure Button1Click(Sender: TObject);
    Procedure Button2Click(Sender: TObject);
    Procedure Button3Click(Sender: TObject);
    Procedure Button4Click(Sender: TObject);
    Procedure ComboBox1Change(Sender: TObject);
    Procedure ComboBox1KeyPress(Sender: TObject; Var Key: char);
    Procedure FormClose(Sender: TObject; Var CloseAction: TCloseAction);
    Procedure FormCreate(Sender: TObject);
    Procedure FormDropFiles(Sender: TObject; Const FileNames: Array Of String);
    Procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    Function Copy_Project_Files(Path: String): String;
    Procedure Load_LPI_File(Const Filename: String);
  End;

Var
  Form1: TForm1;
  FFiles: Array Of String;
  Projectpath: String;
  RecentFiles: Array Of String;
  RecentFile: String;
  ini: tinifile;

Function ToRealFileName(relpath, abspath: String): String;

Implementation

{$R *.lfm}

Uses udomXML, LCLType, Unit2;

{ TForm1 }

Function ToRealFileName(relpath, abspath: String): String;
Var
  i, j, k: Integer;
  s, t: String;
Begin
  // showmessage(relpath + #13#10 + abspath);
{$IFDEF Linux}
  relpath := StringReplace(relpath, '\', PathDelim, [rfReplaceAll]);
  abspath := StringReplace(abspath, '\', PathDelim, [rfReplaceAll]);
{$ELSE}
  relpath := StringReplace(relpath, '/', PathDelim, [rfReplaceAll]);
  abspath := StringReplace(abspath, '/', PathDelim, [rfReplaceAll]);
{$ENDIF}
  If pos('..', relpath) = 0 Then Begin
    result := abspath + relpath;
  End
  Else Begin
    result := '';
    // Zählen der verzeichnisse die zurück gegangen werden müssen.
    i := 0;
    s := relpath;
    While pos('..', s) = 1 Do Begin
      inc(i);
      delete(s, 1, 3); // '..' + Pathdelim
    End;
    t := ExcludeTrailingPathDelimiter(abspath);
    For j := 1 To i Do Begin
      For k := length(t) Downto 1 Do
        If t[k] = PathDelim Then Begin
          t := copy(t, 1, k - 1);
          break;
        End;
    End;
    result := t + PathDelim + s;
  End;
  //  If Not fileexistsUTF8(result) Then Begin
  //    showmessage('Error could not resolve :'#13#10 +
  //      relpath + #13#10 +
  //      abspath + #13#10'To :'#13#10 +
  //      result);
  //  End;
End;

Function PointInRect(P: TPoint; R: TRect): boolean;
Var
  t: Integer;
Begin
  If r.left > r.right Then Begin
    t := r.left;
    r.left := r.right;
    r.right := t;
  End;
  If r.top > r.bottom Then Begin
    t := r.Bottom;
    r.bottom := r.top;
    r.top := t;
  End;
  result := (r.left <= p.x) And (r.right >= p.x) And
    (r.top <= p.y) And (r.bottom >= p.y);
End;

Procedure TForm1.FormCreate(Sender: TObject);
Var
  i: Integer;
  r: Trect;
  IniFilename, s: String;
Begin
  (*
  Wenn die Opendialoge abstürzen, dann leigt das an gtk2 und nicht an Lazarus !!

  sudo rm .gtkrc-2.0-kde4

  behebt das Problem.
  *)
  (*
  Bei einem Multimonitorsystem wollen wir die Anwendung immer da starten wo der Mauscursor ist.
  *)
  If screen.MonitorCount <> 1 Then Begin
    For i := 0 To screen.MonitorCount - 1 Do Begin
      r := screen.Monitors[i].BoundsRect;
      If PointInRect(Mouse.CursorPos, r) Then Begin
        left := (screen.Monitors[i].width - form1.width) Div 2 + screen.Monitors[i].BoundsRect.left;
        top := (screen.Monitors[i].height - form1.height) Div 2 + screen.Monitors[i].BoundsRect.top;
        break;
      End;
    End;
  End
  Else Begin
    left := (screen.width - form1.width) Div 2;
    top := (screen.height - form1.height) Div 2;
  End;
  Constraints.MinWidth := Width;
  Constraints.MinHeight := Height;
  caption := 'Project Collector ver. ' + Version + ' by Corpsman, Support : www.Corpsman.de';
  SelectDirectoryDialog1.InitialDir := ExtractFileDir(paramstr(0));
  OpenDialog1.InitialDir := ExtractFileDir(paramstr(0));
  label2.caption := 'none';
  ComboBox1.Items.Clear;
  ComboBox1.Text := '';
  setlength(RecentFiles, 0);
  IniFilename := IncludeTrailingPathDelimiter(GetAppConfigDir(false)) + 'projectcollector.ini';
  ini := TIniFile.Create(IniFilename);
  For i := 0 To ini.ReadInteger('Recent_lpi', 'Count', 0) - 1 Do Begin
    s := ini.ReadString('Recent_lpi', 'File' + IntToStr(i), '');
    If FileExistsUTF8(s) Then Begin
      setlength(RecentFiles, high(RecentFiles) + 2);
      RecentFiles[high(RecentFiles)] := s;
      ComboBox1.Items.Add(ExtractFileNameOnly(s));
    End;
  End;
  If ComboBox1.Items.Count <> 0 Then ComboBox1.Text := ComboBox1.Items[0];
  s := ini.ReadString('Recent_lpi', 'LastFile', '');
  If FileExistsUTF8(s) Then Begin
    For i := 0 To high(RecentFiles) Do Begin
      If s = RecentFiles[i] Then Begin
        ComboBox1.ItemIndex := i;
        ComboBox1.Hint := RecentFiles[i];
        break;
      End;
    End;
  End;
End;

Procedure TForm1.FormDropFiles(Sender: TObject; Const FileNames: Array Of String
  );
Begin
  If FileExistsUTF8(FileNames[0]) And (lowercase(extractfileext(FileNames[0])) = '.lpi') Then Begin
    Load_LPI_File(FileNames[0]);
  End;
End;

Procedure TForm1.FormClose(Sender: TObject; Var CloseAction: TCloseAction);
Var
  i: integer;
Begin
  ini.WriteInteger('Recent_lpi', 'Count', ComboBox1.Items.Count);
  For i := 0 To ComboBox1.Items.Count - 1 Do Begin
    ini.WriteString('Recent_lpi', 'File' + IntToStr(i), RecentFiles[i]);
  End;
  ini.WriteString('Recent_lpi', 'LastFile', RecentFile);
  ini.Free;
  setlength(RecentFiles, 0);
  setlength(FFiles, 0);
End;

Procedure TForm1.FormShow(Sender: TObject);
Var
  i: integer;
  infile, OutDir, FileErrors: String;
Begin
  (*
   * 2  Modi gibt es
   * 1. Laden eines .lpi Files                      für den Halbautomatischen Betrieb
   * 2. Laden einer -i lpi und eines -o Verzeichnis für den Vollautomatischen Betrieb
   *)
  If Paramcount <> 0 Then Begin
    infile := '';
    OutDir := '';
    For i := 1 To Paramcount Do Begin
      If (LowerCase(ExtractFileExt(ParamStrUTF8(i))) = '.lpi') And FileExistsUTF8(ParamStrUTF8(i)) And (Paramcount = 1) Then Begin
        Load_LPI_File(ParamStrUTF8(i));
        exit;
      End;
      If lowercase(ParamStrUTF8(i)) = '-i' Then Begin
        infile := ParamStrUTF8(i + 1);
        If Not FileExistsUTF8(infile) Then Begin
          showmessage('Error could not locate : ' + infile);
          halt;
        End;
      End;
      If lowercase(ParamStrUTF8(i)) = '-o' Then Begin
        OutDir := IncludeTrailingPathDelimiter(ParamStrUTF8(i + 1));
        If Not DirectoryExistsUTF8(OutDir) Then Begin
          If Not CreateDirUTF8(OutDir) Then Begin
            showmessage('Error could not create : ' + OutDir);
            halt;
          End;
        End;
      End;
    End;
    If (infile = '') Or (OutDir = '') Then Begin
      showmessage('Error either input file or output dir is not set.' + LineEnding +
        'Usage "-i project1.lpi -o ' +
{$IFDEF Windows}
        'c:\Temp\Test\'
{$ELSE}
        '/tmp/test'
{$ENDIF}
        );
      halt;
    End;
    Load_LPI_File(infile);
    FileErrors := Copy_Project_Files(OutDir);
    If FileErrors <> '' Then Begin
      ShowMessage('Error, unable to copy the files:' + LineEnding + FileErrors);
      halt(1);
    End
    Else Begin
      halt(0);
    End;
  End;
End;

Function TForm1.Copy_Project_Files(Path: String): String;
Var
  t: String;
  s: String;
  i: Integer;
Begin
  result := '';
  s := IncludeTrailingPathDelimiter(path);
  For i := 0 To CheckListBox1.items.count - 1 Do Begin
    If CheckListBox1.Checked[i] Then Begin
      CheckListBox1.Selected[i] := true;
      Application.ProcessMessages;
      t := s + ExtractFileName(FFiles[i]);
      If Not CopyFile(FFiles[i], t) Then Begin
        result := result + FFiles[i] + LineEnding;
      End;
    End;
  End;
End;

Procedure TForm1.Load_LPI_File(Const Filename: String);
Var
  Parser: TdomXML;
  t: String;
  ispart: Boolean;
  i: integer;
  fname, siblings, partof, unitNode: TDomNode;
  foundDoubles: Boolean;
Begin
  // Vorbedingungen
  ispart := false;
  For i := 0 To high(RecentFiles) Do Begin
    If RecentFiles[i] = Filename Then Begin
      ispart := true;
      break;
    End;
  End;
  If Not ispart Then Begin
    SetLength(RecentFiles, high(RecentFiles) + 2);
    RecentFiles[high(RecentFiles)] := Filename;
    ComboBox1.Items.Add(ExtractFileNameOnly(Filename));
    ComboBox1.ItemIndex := ComboBox1.Items.Count - 1;
  End;
  ComboBox1.Text := ExtractFileNameOnly(Filename);
  ComboBox1.Hint := Filename;
  RecentFile := Filename;

  CheckListBox1.clear;
  setlength(FFiles, 1);
  ffiles[0] := FileName;
  checklistbox1.items.add(ExtractFileName(FileName));
  checklistbox1.Checked[0] := true;
  Projectpath := IncludeTrailingPathDelimiter(ExtractFileDir(FileName));
  label2.Caption := ExtractFileNameOnly(FileName);

  parser := TDOMXML.Create;
  If Not parser.LoadFromFile(Filename) Then Begin
    showmessage(parser.LastError);
    parser.free;
    exit;
  End;
  unitNode := parser.DocumentElement.FindNode('units', false);
  If Not assigned(unitNode) Then Begin
    showmessage('No units section found.');
    parser.free;
    exit;
  End;
  siblings := unitNode.FirstChild;
  foundDoubles := false;
  While assigned(siblings) Do Begin
    fname := siblings.FindNode('Filename', False);
    If assigned(fname) Then Begin
      ispart := false;
      setlength(FFiles, high(FFiles) + 2);
      FFiles[high(FFiles)] := ToRealFileName(fname.AttributeValue['Value'], Projectpath);
      If Not FileExistsUTF8(FFiles[high(FFiles)]) Then Begin
        (*
         * Die Datei gibt es nicht, evtl. gibt es sie aber im "Lokalen" Verzeichnis der .lpi Datei, dann biegen wir den Pfad um und nehmen sie dennoch :-)
         *)
        t := IncludeTrailingPathDelimiter(ExtractFilePath(Filename)) + ExtractFileName(FFiles[high(FFiles)]);
        If FileExistsUTF8(t) Then Begin
          FFiles[high(FFiles)] := t;
        End;
      End;

      CheckListBox1.Items.Add(ExtractFileName(FFiles[high(FFiles)]));
      partof := siblings.FindNode('IsPartOfProject', False);
      If assigned(partof) Then Begin
        If lowercase(partof.AttributeValue['Value']) = 'true' Then Begin
          ispart := true;
        End;
      End;
      CheckListBox1.Checked[CheckListBox1.Count - 1] := ispart;
      // Doppelte aktive Raus werfen
      For i := 0 To CheckListBox1.Items.Count - 2 Do Begin
        If (CheckListBox1.Items[i] = CheckListBox1.Items[CheckListBox1.Items.Count - 1]) Then Begin
          foundDoubles := true;
          If (CheckListBox1.Checked[i]) Then Begin
            CheckListBox1.Checked[CheckListBox1.Count - 1] := false;
            break;
          End;
        End;
      End;
      // Wenn es eine Unit ist, die eine TForm beinhält, mus auch noch die *.lfm mit kopiert werden.
      t := FFiles[high(FFiles)];
      If lowercase(ExtractFileExt(t)) = '.pas' Then Begin
        t := copy(t, 1, length(t) - 3) + 'lfm';
        // Wenns die LFM gibt.
        If FileExists(t) And ispart Then Begin
          setlength(FFiles, high(FFiles) + 2);
          FFiles[high(FFiles)] := t;
          CheckListBox1.items.add(ExtractFileName(t));
          CheckListBox1.Checked[CheckListBox1.Count - 1] := true;
        End;
      End;
    End;
    siblings := unitNode.NextSibling;
  End;
  If high(ffiles) + 1 <> CheckListBox1.Count Then Begin
    showmessage('Parsing Error invalid unit count found.');
  End;
  parser.free;
  If foundDoubles Then Begin
    If id_yes = application.MessageBox('Found files that are multiple times listed in .lpi, this could leed to errors while projectuncollect, would you like to fix that now?', 'Warning', MB_ICONWARNING Or MB_YESNO) Then Begin
      form2.Load_LPI_File(Filename);
      form2.Showmodal;
      Load_LPI_File(Filename);
    End;
  End;
  Button2.SetFocus;
End;

Procedure TForm1.Button3Click(Sender: TObject);
Begin
  close;
End;

Procedure TForm1.Button4Click(Sender: TObject);
Begin
  If ComboBox1.ItemIndex <> -1 Then Begin
    Load_LPI_File(RecentFiles[ComboBox1.ItemIndex]);
  End;
End;

Procedure TForm1.ComboBox1Change(Sender: TObject);
Begin
  If ComboBox1.ItemIndex <> -1 Then Begin
    ComboBox1.Hint := RecentFiles[ComboBox1.ItemIndex];
  End;
End;

Procedure TForm1.ComboBox1KeyPress(Sender: TObject; Var Key: char);
Begin
  key := #0;
End;

Procedure TForm1.Button1Click(Sender: TObject);
Begin
  If OpenDialog1.execute Then Begin
    Load_LPI_File(OpenDialog1.FileName);
  End;
End;

Procedure TForm1.Button2Click(Sender: TObject);
Var
  k: String;
Begin
  If CheckListBox1.items.count = 0 Then Begin
    showmessage('Error no loaded *.lpi file.');
    exit;
  End;
  If SelectDirectoryDialog1.execute Then Begin
    k := Copy_Project_Files(SelectDirectoryDialog1.FileName);
    If length(k) <> 0 Then
      showmessage('Error could not copy the following files : ' + LineEnding + k)
    Else Begin
      showmessage('Finished without errors.');
      Button3.SetFocus;
    End;
  End;
End;

End.

