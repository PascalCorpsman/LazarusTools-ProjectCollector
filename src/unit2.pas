Unit Unit2;

{$MODE objfpc}{$H+}

Interface

Uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls,
  uDOMXML;

Type

  TFileEntry = Record
    lpi_Value: String; // Der Eintrag der im LPI-File steht
    Real_Filename: String; // Der Berechnete Dateipfad wo die Datei Liegen sollte
    File_name: String; // Der Dateiname, der in der Listbox angezeigt wird
  End;

  TFileListe = Array Of TFileEntry;

  { TForm2 }

  TForm2 = Class(TForm)
    Button1: TButton;
    StringGrid1: TStringGrid;
    Procedure Button1Click(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
    Procedure FormDestroy(Sender: TObject);
    Procedure StringGrid1ButtonClick(Sender: TObject; aCol, aRow: Integer);
  private
    fXML: TDOMXML;
    fOldUnitsStyle: Boolean;
    ffilename: String;
  public
    Procedure Load_LPI_File(aFilename: String);
  End;

Var
  Form2: TForm2;

Implementation

Uses unit1;

{$R *.lfm}

{ TForm2 }

Procedure TForm2.FormCreate(Sender: TObject);
Begin
  fXML := TDOMXML.Create;
  caption := 'Project file editor.';
End;

Procedure TForm2.Button1Click(Sender: TObject);
Var
  siblings, unitNode: TDomNode;
  cnt: integer;
Begin
  // Speichern
  If fOldUnitsStyle Then Begin
    cnt := 0;
    // Beim Alten Style haben die Knoten Namen aufsteigende Zahlen und im Attribut steht der Count
    unitNode := fXML.DocumentElement.FindNode('units', false);
    siblings := unitNode.FirstChild;
    While assigned(siblings) Do Begin
      siblings.NodeName := 'Unit' + inttostr(cnt);
      inc(cnt);
      siblings := unitNode.NextSibling;
    End;
    unitNode.AttributeValue['Count'] := inttostr(cnt);
  End;
  fXML.Indent := '  ';
  fXML.SaveToFile(ffilename);
  close;
End;

Procedure TForm2.FormDestroy(Sender: TObject);
Begin
  fXML.free;
End;

Procedure TForm2.StringGrid1ButtonClick(Sender: TObject; aCol, aRow: Integer);
Var
  File_name, Real_Filename, lpi_Value: String;
  fname, siblings, unitNode: TDomNode;
Begin
  unitNode := fXML.DocumentElement.FindNode('units', false);
  siblings := unitNode.FirstChild;
  While assigned(siblings) Do Begin
    fname := siblings.FindNode('Filename', False);
    If assigned(fname) Then Begin
      lpi_Value := fname.AttributeValue['Value'];
      Real_Filename := ToRealFileName(lpi_Value, Projectpath);
      File_name := ExtractFileName(Real_Filename);
      If (StringGrid1.Cells[0, aRow] = File_name) And
        (StringGrid1.Cells[1, aRow] = Real_Filename) And
        (StringGrid1.Cells[3, aRow] = lpi_Value) Then Begin
        siblings.Free;
        StringGrid1.DeleteRow(aRow);
        break;
      End;
    End;
    siblings := unitNode.NextSibling;
  End;
End;

Procedure TForm2.Load_LPI_File(aFilename: String);
Var
  fname, unitNode, siblings: TDomNode;
  s: String;
  i, j: Integer;
  ffiles: TFileListe;
  found: Boolean;
Begin
  ffilename := aFilename;
  setlength(ffiles, 0);
  fXML.Clear;
  fXML.LoadFromFile(aFilename);
  unitNode := fXML.DocumentElement.FindNode('units', false);
  fOldUnitsStyle := unitNode.AttributeValue['Count'] <> '';
  // Auslesen aller Dateien
  siblings := unitNode.FirstChild;
  While assigned(siblings) Do Begin
    fname := siblings.FindNode('Filename', False);
    If assigned(fname) Then Begin
      setlength(ffiles, high(ffiles) + 2);
      FFiles[high(FFiles)].lpi_Value := fname.AttributeValue['Value'];
      FFiles[high(FFiles)].Real_Filename := ToRealFileName(FFiles[high(FFiles)].lpi_Value, Projectpath);
      FFiles[high(FFiles)].File_name := ExtractFileName(FFiles[high(FFiles)].Real_Filename);
    End;
    siblings := unitNode.NextSibling;
  End;
  // Nur die Doppelten auflisten und dann auch immer Sortiert
  StringGrid1.RowCount := 1;
  For i := 0 To high(ffiles) - 1 Do Begin
    found := false;
    For j := i + 1 To high(ffiles) Do Begin
      If ffiles[i].File_name = ffiles[j].File_name Then Begin
        // Den Eintrag i übernehmen wir nur beim 1.Mal
        If Not Found Then Begin
          StringGrid1.RowCount := StringGrid1.RowCount + 2;
          StringGrid1.Cells[0, StringGrid1.RowCount - 2] := ffiles[i].File_name;
          StringGrid1.Cells[1, StringGrid1.RowCount - 2] := ffiles[i].Real_Filename;
          StringGrid1.Cells[2, StringGrid1.RowCount - 2] := 'Delete';
          StringGrid1.Cells[3, StringGrid1.RowCount - 2] := ffiles[i].lpi_Value;
        End
        Else Begin
          StringGrid1.RowCount := StringGrid1.RowCount + 1;
        End;
        found := true;
        // Der Eintrag j wird natürlich jedes mal eingefügt.
        StringGrid1.Cells[0, StringGrid1.RowCount - 1] := ffiles[j].File_name;
        StringGrid1.Cells[1, StringGrid1.RowCount - 1] := ffiles[j].Real_Filename;
        StringGrid1.Cells[2, StringGrid1.RowCount - 1] := 'Delete';
        StringGrid1.Cells[3, StringGrid1.RowCount - 1] := ffiles[j].lpi_Value;
      End;
    End;
  End;
  StringGrid1.AutoSizeColumns;
End;

End.

