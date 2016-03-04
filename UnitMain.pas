unit UnitMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  IPPeerClient, Vcl.ComCtrls, REST.Authenticator.OAuth, REST.Client,
  Data.Bind.Components, Data.Bind.ObjectScope, REST.Types, REST.Utils,
  REST.Authenticator.OAuth.WebForm.Win, Vcl.OleCtrls, SHDocVw, UnitHandle,
  Vcl.ImgList;

type
  TfrmMain = class(TForm)
    TwitterTimer: TTimer;
    edMessage: TEdit;
    btnSendTwitter: TButton;
    btnSendFacebook: TButton;
    btnClearCache: TButton;
    ImageList1: TImageList;
    procedure btnSendTwitterClick(Sender: TObject);
    procedure btnSendFacebookClick(Sender: TObject);
    procedure btnClearCacheClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FacebookHandle: TSocialHandle;
    TwitterHandle: TSocialHandle;
    procedure EmptyIECache;

  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses ActiveX, mshtml, Winapi.WinInet;

{ TfrmMain }

procedure TfrmMain.btnClearCacheClick(Sender: TObject);
begin
  EmptyIECache;
end;

procedure TfrmMain.btnSendFacebookClick(Sender: TObject);
  var
    LURL: String;
begin
    if not Assigned(FacebookHandle) then
      FacebookHandle := TFacebookHandle.Create;
    if Assigned(FacebookHandle) then
    try
      try
        if FacebookHandle.ConnectToFacebook then
        begin
          //FacebookHandle.PostToTwitter(Trim('I used ZIPmagic DoubleSpace 3 to compress my disk and I''m very happy with the results!'));
          //FacebookHandle.PostToTwitter(Trim('ZIPmagic DoubleSpace 3 created ' + FormatByteSize((tb - hb) - tbex) + ' of free space for me without deleting anything.'));
          FacebookHandle.PostToFacebook(
            Trim('My ZIPmagic DoubleSpace 3 grew my disk from 111 and even improved my disk read speeds...') +
            Trim('My ZIPmagic DoubleSpace 3 compressed my disk at a ratio of 2222 to 1, while preserving all of my apps, files, and settings.') +
            Trim('My ZIPmagic DoubleSpace 3 gave me 21212 of extra space in a single click, without deleting anything!'));
          {FacebookHandle.PostToFacebook(Trim('My ZIPmagic DoubleSpace 3 grew my disk from ' + FormatByteSize(ts) + ' to ' + FormatByteSize(tsx) + ', and even improved my disk read speeds...'));
          FacebookHandle.PostToFacebook(Trim('My ZIPmagic DoubleSpace 3 compressed my disk at a ratio of ' + sEY + ' to 1, while preserving all of my apps, files, and settings.'));
          FacebookHandle.PostToFacebook(Trim('My ZIPmagic DoubleSpace 3 gave me ' + FormatByteSize((tb - hb) - tbex) + ' of extra space in a single click, without deleting anything!'));
          }
        end;
      except
        // eatISO
      end;
      //ShowMessage('Success');
    finally
      //FreeAndNil(FacebookHandle);
    end;
end;

procedure TfrmMain.btnSendTwitterClick(Sender: TObject);
begin
if not Assigned(TwitterHandle) then
      TwitterHandle := TTwitterHandle.Create;
    if Assigned(TwitterHandle) then
    try
      try
        if TwitterHandle.ConnectToTwitter then
        begin
          //TwitterHandle.PostToTwitter(Trim('I used ZIPmagic DoubleSpace 3 to compress my disk and I''m very happy with the results!'));
          //TwitterHandle.PostToTwitter(Trim('ZIPmagic DoubleSpace 3 created ' + FormatByteSize((tb - hb) - tbex) + ' of free space for me without deleting anything.'));
          TwitterHandle.PostToTwitter(Trim('My ZIPmagic DoubleSpace 3 grew my disk from 222 to 111, and even improved my disk read speeds...'));
          TwitterHandle.PostToTwitter(Trim('My ZIPmagic DoubleSpace 3 compressed my disk at a ratio of 222 to 1, while preserving all of my apps, files, and settings.'));
          TwitterHandle.PostToTwitter(Trim('My ZIPmagic DoubleSpace 3 gave me 22222 of extra space in a single click, without deleting anything!'));
        end;
      except
        // eatISO
      end;
      //ShowMessage('Success');
    finally
      //FreeAndNil(TwitterHandle);
    end;
end;

procedure TfrmMain.EmptyIECache;
Var
    lpEntryInfo : PInternetCacheEntryInfo;
    hCacheDir   : LongWord;
    dwEntrySize : LongWord;
    dwLastError : LongWord;
Begin
    dwEntrySize := 0;
    FindFirstUrlCacheEntry( NIL, TInternetCacheEntryInfo( NIL^ ), dwEntrySize );
    GetMem( lpEntryInfo, dwEntrySize );
    hCacheDir := FindFirstUrlCacheEntry( NIL, lpEntryInfo^, dwEntrySize );
    If ( hCacheDir <> 0 ) Then
        DeleteUrlCacheEntry( lpEntryInfo^.lpszSourceUrlName );
    FreeMem( lpEntryInfo );
    Repeat
        dwEntrySize := 0;
        FindNextUrlCacheEntry( hCacheDir, TInternetCacheEntryInfo( NIL^ ), dwEntrySize );
        dwLastError := GetLastError();
        If ( GetLastError = ERROR_INSUFFICIENT_BUFFER ) Then Begin
            GetMem( lpEntryInfo, dwEntrySize );
            If ( FindNextUrlCacheEntry( hCacheDir, lpEntryInfo^, dwEntrySize ) ) Then
                DeleteUrlCacheEntry( lpEntryInfo^.lpszSourceUrlName );
            FreeMem(lpEntryInfo);
        End;
    Until ( dwLastError = ERROR_NO_MORE_ITEMS );
End;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FacebookHandle := TFacebookHandle.Create;
  TwitterHandle := TTwitterHandle.Create;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FacebookHandle);
  FreeAndNil(TwitterHandle);
end;

end.
