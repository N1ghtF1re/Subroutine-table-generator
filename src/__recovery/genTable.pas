unit genTable;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.StdCtrls,ComObj, pngimage,
  Vcl.ExtCtrls, Vcl.Menus, ShellAPI,SplashScreen, IdHTTP, IdBaseComponent,
  IdComponent, IdTCPConnection, IdTCPClient, NewVersion;

type
  TTableGenForm = class(TForm)
    memoInpCode: TMemo;
    StringGrid1: TStringGrid;
    btnToExcel: TButton;
    btnGenTable: TButton;
    pnlBottom: TPanel;
    SaveDialog1: TSaveDialog;
    MainMenu1: TMainMenu;
    mnFile: TMenuItem;
    mnClear: TMenuItem;
    mnSupport: TMenuItem;
    mniConver: TMenuItem;
    mnToExcel: TMenuItem;
    ImgIntro: TImage;
    IdHTTP1: TIdHTTP;
    procedure btnToExcelClick(Sender: TObject);
    procedure btnGenTableClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure mniConverClick(Sender: TObject);
    procedure mnToExcelClick(Sender: TObject);
    procedure mnClearClick(Sender: TObject);
    procedure mnSupportClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    splash: TSplash;
      function GetExcelFileName: String;
  public
    version: String;
    HTMLtext:String;
  end;

var
  TableGenForm: TTableGenForm;
  isOK: boolean;
implementation

{$R *.dfm}

const
  EXCEL_FILE_EXT = '.docx';

function TTableGenForm.GetExcelFileName: String;
begin
  if SaveDialog1.Execute then
    Result := SaveDialog1.FileName;

  if LowerCase(ExtractFileExt(Result)) <> EXCEL_FILE_EXT then
    Result := Result + EXCEL_FILE_EXT;
end;


procedure TTableGenForm.mnClearClick(Sender: TObject);
begin
  memoInpCode.Clear;
end;

procedure TTableGenForm.mniConverClick(Sender: TObject);
begin
  btnGenTable.Click;
end;


procedure TTableGenForm.mnSupportClick(Sender: TObject);
begin
   ShellExecute(Application.Handle, nil, 'https://vk.com/@brakhmen-podderzhat-brakhmen-corparation', nil, nil,SW_SHOWNOACTIVATE);
end;

procedure TTableGenForm.mnToExcelClick(Sender: TObject);
begin
  btnToExcel.Click;
end;

procedure TTableGenForm.btnToExcelClick(Sender: TObject);
var
 Word,WordTable: variant;
 Col, Row: Integer;
 i,j:integer;
begin
  col := StringGrid1.ColCount;
  row := StringGrid1.RowCount;

  // Сохраняем все в Word файл!
  Word:=CreateOleObject('Word.Application');
  try
    Word.Documents.Add;
    Word.ActiveDocument.Tables.Add(Word.ActiveDocument.Range,
    row,col);

    WordTable:=Word.ActiveDocument.Tables.Item(1);
    WordTable.Style:='Сетка таблицы';
    ShowMessage( IntToStr(row) + ' ' + IntToStr(col) );
    For i:=1 To row Do
    Begin
      For j:=1 To col Do
      begin
        if i = 1 then
          WordTable.Cell(1, j).Range.Font.Bold:=True;
        WordTable.Cell(I, j).Range.Text:=StringGrid1.cells[j-1,i-1];
        //ShowMessage(StringGrid1.cells[j-1,i-1]);
      end;

    End;
    if SaveDialog1.Execute then
    Word.ActiveDocument.SaveAs(SaveDialog1.FileName);
    ShowMessage('Сохранено');
  finally
    Word.Application.Quit;
    Word := unassigned;
  end;
end;

procedure TTableGenForm.btnGenTableClick(Sender: TObject);
var i,j,k:integer;
    curr:string;
    b1, b2:integer;
    variable:string;
    currvar:string;
begin
  //showmessage( inttostr( Length(memoInpCode.Text)) );
  j:=1;
  isOk := false;
  StringGrid1.Cells[0,0] := 'Имя подпрограммы';
  StringGrid1.Cells[1,0] := 'Описание';
  StringGrid1.Cells[2,0] := 'Заголовок подпрограммы';
  StringGrid1.Cells[3,0] := 'Имя параметра';
  StringGrid1.Cells[4,0] := 'Назначение параметра';
  for I := 0 to memoInpCode.Lines.Count-1 do
  begin
    if (pos('implementation', AnsiLowerCase(memoInpCode.Lines[i])) > 0) or (pos('$APPTYPE CONSOLE', memoInpCode.Lines[i]) > 0) then
    begin
      isOk := true;
    end;
    if (pos('interface', AnsiLowerCase(memoInpCode.Lines[i])) > 0) then
      isOk := false;

    curr := trim(memoInpCode.Lines[i]);
    b1 := pos('PROCEDURE',AnsiUpperCase(curr));
    b2 := pos('FUNCTION', AnsiUpperCase(curr));

    if isOk and
    (
    ( b1 > 0)
    or
    (b2 > 0)) then
    begin      

      if (b1 > 1) or (b2 > 1) then
      begin
        if b1 = 0 then
          k := b2
        else
          k := b1;

        if pos('=', curr) < k then
          continue; // Процедурный тип
      end;
      
      if (pos('(', curr) <> 0) and (pos(')', curr) = 0) then
      begin
        k:=1;
        while (pos(')', curr) = 0) do
        begin
          curr := curr + memoInpCode.Lines[i+k];
          inc(k);
        end;

      end;

      StringGrid1.Cells[2,j] := curr;
      // Удаляем слова procedure, function для названия подпрограммы
      if b1 > 0 then
      begin
        delete(curr,1,b1+9);
      end
      else
      begin
        delete(curr,1,b1+9);
      end;
      curr := trim(curr);
      // Если при задании процедуры указывается класс, убираем его
      if (UpperCase(curr[1]) = 'T') and (pos('.', curr) <> 0) then
      begin
        delete(curr,1, pos('.', curr));
      end;
      // Удаляем
      if pos('(', curr) <> 0 then
      begin
        variable := copy(curr, pos('(', curr)+1, length(curr));
        curr := copy(curr,0, pos('(', curr)-1);

        k := 1;
        while pos('var', variable) > 0 do
          delete(variable, pos('var', variable), 4);
        while pos('const', variable) > 0 do
          delete(variable, pos('const', variable), 6);
        while pos('out', variable) > 0 do
          delete(variable, pos('out', variable), 4);

        while(variable[k] <> ')') do
        begin
          if variable[k] = ':' then
          begin
            //showmessage('lel');
            currvar := trim(Copy(variable,1,k-1));
            StringGrid1.Cells[3,j] := currvar;
            if AnsiLowerCase(currvar) = 'sender' then
              StringGrid1.Cells[4,j] := 'Объект, который сгенерировал событие';
          end;
          inc(k);
        end;
      end;


      StringGrid1.Cells[0,j] := curr;
      //StringGrid1.Cells[3,j] := variable;

      if pos('CLICK', AnsiUpperCase(curr)) > 0 then
        StringGrid1.Cells[1,j] := 'Обработка клика';
      if pos('CREATE', AnsiUpperCase(curr)) > 0 then
        StringGrid1.Cells[1,j] := 'Событие при создании формы';
      if pos('MOUSE', AnsiUpperCase(curr)) > 0 then
        StringGrid1.Cells[1,j] := 'Обработка нажатие мыши';


      inc(j);
      stringGrid1.RowCount := j;
    end;

  end;

end;

procedure TTableGenForm.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  memoInpCode.Width := TableGenForm.Width div 2;
  StringGrid1.Left := memoInpCode.Width;
  StringGrid1.Width := TableGenForm.Width div 2 - 15;
  StringGrid1.DefaultColWidth := StringGrid1.Width div 5 - 12;
  memoinpcode.Height := TableGenForm.Height - pnlBottom.Height - 20;
  StringGrid1.Height := memoInpCode.Height;
  btnGenTable.Width := memoInpCode.Width;
  btnToExcel.Left := StringGrid1.Left;
  btnToExcel.Width := StringGrid1.Width;

end;

procedure TTableGenForm.FormCreate(Sender: TObject);
var 
  png: TPngImage;
begin
  isOk := false;
  png:= TPngImage(ImgIntro.Picture);
  Splash := TSplash.Create(png);
  Splash.Show(true);
  // HTMLtext := IDHttp1.Get('http://pankratiew.info/TPG_vers.brakh');
  Sleep(2000);
  Splash.Close;


end;

procedure TTableGenForm.FormShow(Sender: TObject);
begin
  version:='1.1';
  if ( (Pos(version,HTMLtext)<>0) or (HTMLtext = ''))  then
  begin

  end
  else
  begin
    Application.CreateForm(TFormVers, FormVers);
    FormVers.ShowModal;
  end;
end;

end.