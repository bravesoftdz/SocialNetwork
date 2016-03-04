unit UnitHandle;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  IPPeerClient, Vcl.ComCtrls, REST.Authenticator.OAuth, REST.Client,
  Data.Bind.Components, Data.Bind.ObjectScope, REST.Types, REST.Utils,
  REST.Authenticator.OAuth.WebForm.Win, Vcl.OleCtrls, SHDocVw,
  ActiveX, mshtml, Winapi.WinInet;

type
  TSocialHandle = class
    FBaseURL: String;
    FResourseURI: String;
    FConsumerKey: String;
    FConsumerSecret: String;
    FRequestToken: String;
    FRequestTokenSecret: String;
    FAccessToken: String;
    FAccessTokenSecret: String;
    FPIN: String;
    FClientID: String;
    FClientSecret: String;
    FRestClient: TRESTClient;
    FRestRequest: TRESTRequest;
    FRestResponse: TRESTResponse;
    FAuth1: TOAuth1Authenticator;
    FAuth2: TOAuth2Authenticator;
    FFacebookId: String;
    FButtonName: String;
    FEditName: String;
    FWebBrowser: TWebBrowser;
    FForm: TForm;
    FFacePageComplete: Boolean;
  private
    FTimer: TTimer;
    OForm: Tfrm_OAuthWebForm;

    procedure OAuth2_Facebook_AccessTokenRedirect(const AURL: string; var DoCloseWebView: boolean);
    procedure Facebook_SendMessage(const AURL: string; var DoCloseWebView: boolean);

    procedure FacebookDocumentComplete(ASender: TObject; const pDisp: IDispatch;
      const URL: OleVariant);
    procedure OnTwitterTimerTimer(Sender: TObject);
    procedure OnFacebookTimerTimer(Sender: TObject);
  protected
    FText: String;
    FSuccessSend: Boolean;
  public
    constructor Create; virtual;
    destructor Destroy; virtual;
    function PostToTwitter(szText: String ): Boolean;
    function PostToFacebook(szText: String ): Boolean;
    function ConnectToTwitter: Boolean;
    function ConnectToFacebook: Boolean;

    property BaseURL: String read FBaseURL write FBaseURL;
    property ResourseURI: String read FResourseURI write FResourseURI;
    property ConsumerKey: String read FConsumerKey write FConsumerKey;
    property ConsumerSecret: String read FConsumerSecret write FConsumerSecret;
    property RequestToken: String read FRequestToken write FRequestToken;
    property RequestTokenSecret: String read FRequestTokenSecret write FRequestTokenSecret;
    property AccessToken: String read FAccessToken write FAccessToken;
    property AccessTokenSecret: String read FAccessTokenSecret write FAccessTokenSecret;
    property PIN: String read FPIN write FPIN;
    property ClientID: String read FClientID write FClientID;
    property ClientSecret: String read FClientSecret write FClientSecret;
    property RestClient: TRESTClient read FRestClient write FRestClient;
    property RestRequest: TRESTRequest read FRestRequest write FRestRequest;
    property RestResponse: TRESTResponse read FRestResponse write FRestResponse;
    property Auth1: TOAuth1Authenticator read FAuth1 write FAuth1;
    property Auth2: TOAuth2Authenticator read FAuth2 write FAuth2;
    property Text: String read FText write FText;
    property FacebookId: String read FFacebookId write FFacebookId;
    property NForm: Tfrm_OAuthWebForm read OForm;
    property ButtonName: String read FButtonName;
end;

type
  TFacebookHandle = class(TSocialHandle)

  public
    constructor Create; override;
    destructor Destroy; override;
  end;

type
  TTwitterHandle = class(TSocialHandle)

  public
    constructor Create; override;
    destructor Destroy; override;
  end;

implementation

procedure TSocialHandle.OAuth2_Facebook_AccessTokenRedirect(const AURL: string; var DoCloseWebView: boolean);
var
  LATPos: integer;
  LToken: string;
begin
  LATPos := Pos('access_token=', AURL);
  if (LATPos > 0) then
  begin
    LToken := Copy(AURL, LATPos + 13, Length(AURL));
    if (Pos('&', LToken) > 0) then
    begin
      LToken := Copy(LToken, 1, Pos('&', LToken) - 1);
    end;

    FAccessToken := LToken;
    if (LToken <> '') then
      DoCloseWebView := True;
  end;
end;

procedure TSocialHandle.FacebookDocumentComplete(ASender: TObject;
  const pDisp: IDispatch; const URL: OleVariant);
  var
    form:olevariant;
    i,f:Integer;
    FTextComplete, FButtonComplete: Boolean;
begin
  if FTimer.Enabled then Exit;
  if FSuccessSend then Exit;
  if FFacePageComplete then Exit;

  FTextComplete := False;
  FButtonComplete := False;
  for f := 0 to FWebBrowser.OleObject.Document.forms.Length - 1 do
  begin
    FFacePageComplete := True;
    form := FWebBrowser.OleObject.Document.forms.Item(f).elements;
    for i := 0 to form.Length - 1 do
    begin
      if (form.item(i).id=FEditName) then
      begin
        form.item(i).value := FText;
        FTextComplete := True;
      end;
      if (form.item(i).id=FButtonName) then
      begin
        if FTextComplete then
        begin
          form.item(i).Disabled := 0;
          form.item(i).click;
          FButtonComplete := True;
          Break;
        end;
      end;
    end;
    if FButtonComplete then
    begin
      Break;
    end;
  end;
  FTimer.Enabled := FButtonComplete;
end;

procedure TSocialHandle.Facebook_SendMessage(const AURL: string;
  var DoCloseWebView: boolean);
var
  LATPos: integer;
  LToken: string;
begin
  LATPos := Pos('post_id=', AURL);
  if (LATPos > 0) then
  begin
    LToken := Copy(AURL, LATPos + 8, 31);
    if Length(LToken) > 0 then
    begin
      FSuccessSend := True;
    end;

    if (LToken <> '') then
      DoCloseWebView := True;
  end;
end;

function TSocialHandle.PostToFacebook(szText: String): Boolean;
  var QueryString: String;
      rrp: TRESTRequestParameter;
      Response: AnsiString;
      LURL: String;
      wv: Tfrm_OAuthWebForm;
      form:olevariant;
      i,f:Integer;
      FTextComplete, FButtonComplete: Boolean;
begin

  Result := False;

//  FRESTRequest.ResetToDefaults;
//  FRESTClient.ResetToDefaults;
//  FRESTResponse.ResetToDefaults;
  FText := '';
  FFacePageComplete := False;
  FSuccessSend := False;
{
  FRESTClient.BaseURL := 'https://graph.facebook.com/me/feed';

//  FRESTClient.BaseURL := 'https://www.facebook.com/dialog/feed';
  FRestRequest.Method := TRESTRequestMethod.rmPOST;

  QueryString := '?access_token=' + FAccessToken;
//  QueryString := '?app_id=' + FClientID;
//  QueryString := QueryString + '&link=http://developers.facebook.com/docs/reference/dialogs/';
//  QueryString := QueryString + '&name=Facebook%20Dialogs';
//  QueryString := QueryString + '&caption=Reference%20Documentation';
//  QueryString := QueryString + '&message=' + szText;
//  QueryString := QueryString + '&redirect_uri=https://www.facebook.com/connect/login_success.html';
  QueryString := QueryString + '&message=' + szText;
  FRESTClient.BaseURL := FRESTClient.BaseURL + QueryString;

  FRESTRequest.Execute;
}

//  OForm := Tfrm_OAuthWebForm.Create(nil);
  FText := szText;
  try

    LURL := 'https://www.facebook.com/dialog/feed';
    LURL := LURL + '?app_id=' + FClientID;
//    LURL := LURL + '&name=Facebook%20Dialogs';
//    LURL := LURL + '&caption=Reference%20Documentation';
//    LURL := LURL + '&message=' + szText;
    LURL := LURL + '&redirect_uri=https://www.facebook.com/connect/login_success.html';

//    wv.OnAfterRedirect := Facebook_SendMessage;
//    OForm.ShowModalWithURL(LURL);
    FWebBrowser.Navigate(LURL);
    if FForm.ShowModal = mrOk then
    begin

    end;
  finally
//    OForm.Release;
  end;
{
  if FRestResponse.StatusCode = 200 then
    Result := True
  else
    ShowMessage('Failed. Reason: ' + FRestResponse.StatusText);
}
end;

function TSocialHandle.PostToTwitter(szText: String): Boolean;
  var
    i: Integer;
begin

  Result := False;

  FRESTRequest.ResetToDefaults;
  FRESTClient.ResetToDefaults;
  FRESTResponse.ResetToDefaults;

  FRESTClient.BaseURL := FBaseURL;
  FRESTClient.Authenticator := FAuth1;

  FRESTRequest.Resource := FResourseURI;

  FRESTRequest.Method := TRESTRequestMethod.rmPOST;
  FRESTRequest.Params.AddItem('status', szText, TRESTRequestParameterKind.pkGETorPOST);

  FRESTRequest.Execute;

  if FRestResponse.StatusCode = 200 then
    Result := True
//  else
//    ShowMessage('Failed. Reason: ' + FRestResponse.StatusText);
end;

procedure TSocialHandle.OnFacebookTimerTimer(Sender: TObject);
var
  LStream: TStringStream;
  Stream : IStream;
  LPersistStreamInit : IPersistStreamInit;
  CodePos: Integer;
begin
  if not Assigned(FWebBrowser.Document) then Exit;

  LStream := TStringStream.Create('', TEncoding.UTF8);
  try
    LPersistStreamInit := FWebBrowser.Document as IPersistStreamInit;
    Stream := TStreamAdapter.Create(LStream,soReference);
    LPersistStreamInit.Save(Stream,true);
    CodePos := Pos('SUCCESS',UpperCase(LStream.DataString));
    if CodePos > 0 then
    begin
      FTimer.Enabled := False;
      FForm.ModalResult := mrOk;
      FSuccessSend := True;
//      ShowMessage('Success');
    end;
  finally
    LStream.Free();
  end;
end;

procedure TSocialHandle.OnTwitterTimerTimer(Sender: TObject);
var
  LStream: TStringStream;
  Stream : IStream;
  LPersistStreamInit : IPersistStreamInit;
  CodePos: Integer;
  myStr: String;
begin
  if OForm <> nil then
  begin
    if not Assigned(OForm.Browser) then Exit;
    if not Assigned(OForm.Browser.Document) then Exit;
    LStream := TStringStream.Create('', TEncoding.UTF8);
    try
      LPersistStreamInit := OForm.Browser.Document as IPersistStreamInit;
      Stream := TStreamAdapter.Create(LStream,soReference);
      LPersistStreamInit.Save(Stream,true);
      CodePos := Pos('LABELLEDBY="CODE-DESC"',UpperCase(LStream.DataString));
      if CodePos > 0 then
      begin
        myStr := Copy(LStream.DataString, CodePos, 50);
        CodePos := Pos('</CODE>', UpperCase(myStr));

        if CodePos > 0 then
        begin
          FTimer.Enabled := False;
//          MemoLog.Lines.Add( Copy(myStr, 30, CodePos - 30) );
          FPIN := Copy(myStr, 30, CodePos - 30);
          OForm.btn_Close.Click;
        end;
      end;
    finally
      LStream.Free();
    end;
  end;
end;

function TSocialHandle.ConnectToFacebook: Boolean;
  var
    LURL: String;
    wv: Tfrm_OAuthWebForm;
begin
  Result := False;

//  FClientID := '966973036714614';
//  FClientSecret := '81456583b82ea096104465427c71626b';
  FClientID := '973193956103804';
//  FClientID := '1570752329913952';
  FClientSecret := '7ea7f7e114939fc9ad798481db0a84b3';
  FBaseURL := 'https://graph.facebook.com';
  FAccessToken := '';
//  FacebookHandle.ResourseURI := 'me?fields=name,birthday,phone,friends.limit(10).fields(name)';

  wv := Tfrm_OAuthWebForm.Create(nil);

  try

    LURL := 'https://www.facebook.com/dialog/oauth';
    LURL := LURL + '?app_id=' + (FClientID);
    LURL := LURL + '&response_type=token';
    LURL := LURL + '&scope=' + URIEncode('publish_actions');
    LURL := LURL + '&redirect_uri=' + URIEncode('https://www.facebook.com/connect/login_success.html');

    wv.OnAfterRedirect := OAuth2_Facebook_AccessTokenRedirect;
    wv.ShowModalWithURL(LURL);

  finally
    wv.Release;
  end;

  if FAccessToken <> '' then
    Result := True;
end;

function TSocialHandle.ConnectToTwitter: Boolean;
  var
    LToken: string;
    LURL: string;
begin
  Result := False;
{
  if FAccessTokenSecret <> '' then
  begin
    FTwitterTimer.Enabled := False;
    Result := True;
    Exit;
  end;
}

  FRESTRequest.ResetToDefaults;
  FRESTClient.ResetToDefaults;
  FRESTResponse.ResetToDefaults;

  FPIN := '';
  FTimer.Enabled := True;

  FBaseURL := 'https://api.twitter.com';
  FResourseURI := '1.1/statuses/update.json';

  /// we need to transfer the data here manually
  FAuth1.ConsumerKey := 'FlG2oUDtPgK8vLQr4pcgJvEyD';
  FAuth1.ConsumerSecrect := 'iA9rAa1AIJJBmQQpenRCO1V5VGhLqG16EoDBPFd0aJ7g1VB072';
//  FAuth1.ConsumerKey := 'kZiOUqbWBHtI4N5FhBDHsAZdX';
//  FAuth1.ConsumerSecrect := 'QG1GPUYERu4fQ4FEraBnVdJTpUMXk11uCNpX8srABe0zTldHW7';

  FAuth1.AccessToken := '';
  FAuth1.AccessTokenSecret := '';
  FAuth1.RequestToken := '';
  FAuth1.RequestTokenSecret := '';
  FAuth1.VerifierPIN := '';

  /// step #1, get request-token
  FRESTClient.BaseURL := FAuth1.RequestTokenEndpoint;
  FRESTClient.Authenticator := FAuth1;

  FRESTRequest.Method := TRESTRequestMethod.rmPOST;

  FRESTRequest.Execute;

  if FRESTResponse.GetSimpleValue('oauth_token', LToken) then
    FAuth1.RequestToken := LToken;
  if FRESTResponse.GetSimpleValue('oauth_token_secret', LToken) then
    FAuth1.RequestTokenSecret := LToken;

  FRequestToken := FAuth1.RequestToken;
  FRequestTokenSecret := FAuth1.RequestTokenSecret;

  /// step #2: get the auth-verifier (PIN must be entered by the user!)
  LURL := FAuth1.AuthenticationEndpoint;
  LURL := LURL + '?oauth_token=' + FAuth1.RequestToken;

  OForm := Tfrm_OAuthWebForm.Create(nil);
  try
    OForm.ShowModalWithURL(LURL);
  finally
    OForm.Release;
  end;

  FRESTRequest.ResetToDefaults;
  FRESTClient.ResetToDefaults;
  FRESTResponse.ResetToDefaults;

  /// grab the verifier from the edit-field
  if FPIN = '' then Exit;
  
  FAuth1.VerifierPIN := FPIN;

  /// here, we want to change the request-token and the verifier into an access-token
  if (FAuth1.RequestToken = '') or (FAuth1.VerifierPIN = '') then
  begin
    TaskMessageDlg('Error', 'Request-token and verifier are both required.', mtError, [mbOK], 0);
    Exit;
  end;

  /// we want to request an access-token
  FAuth1.AccessToken := '';
  FAuth1.AccessTokenSecret := '';

  FRESTClient.BaseURL := FAuth1.AccessTokenEndpoint;
  FRESTClient.Authenticator := FAuth1;

  FRESTRequest.Method := TRESTRequestMethod.rmPOST;
  FRESTRequest.Params.AddItem('oauth_verifier',
    FAuth1.VerifierPIN, TRESTRequestParameterKind.pkGETorPOST,
    [TRESTRequestParameterOption.poDoNotEncode]);

  FRESTRequest.Execute;

  if FRESTResponse.GetSimpleValue('oauth_token', LToken) then
    FAuth1.AccessToken := LToken;
  if FRESTResponse.GetSimpleValue('oauth_token_secret', LToken) then
    FAuth1.AccessTokenSecret := LToken;

  /// now we should remove the request-token
  FAuth1.RequestToken := '';
  FAuth1.RequestTokenSecret := '';
  FAuth1.VerifierPin := '';

  FAccessToken := FAuth1.AccessToken;
  FAccessTokenSecret := FAuth1.AccessTokenSecret;
  FRequestToken := FAuth1.RequestToken;
  FRequestTokenSecret := FAuth1.RequestTokenSecret;

  if FRESTResponse.StatusCode = 200 then
    Result := True
//  else
//    ShowMessage('Failed. Reason: ' + FRestResponse.StatusText);
end;

constructor TSocialHandle.Create;
begin
  inherited;
end;

destructor TSocialHandle.Destroy;
begin
  inherited;
end;

{ TFacebookHandle }

constructor TFacebookHandle.Create;
begin
  inherited;
  // Create REST Client, Request, etc.
  FAuth2 := TOAuth2Authenticator.Create(nil);
  FAuth2.ResponseType := TOAuth2ResponseType.rtTOKEN;
  FAuth2.AccessToken := FAccessToken;

  FRESTClient := TRESTClient.Create('');
  FRESTClient.Authenticator := FAuth2;
  FRESTClient.Accept := 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';
  FRESTClient.HandleRedirects := True;
  FRESTClient.BaseURL := 'https://graph.facebook.com/';

  FRESTRequest := TRESTRequest.Create(nil);
  FRESTRequest.Client := FRESTClient;
  FRESTRequest.Method := TRESTRequestMethod.rmGET;
  FRESTRequest.SynchronizedEvents := False;
//  FRESTRequest.Resource := 'me?fields=name,birthday,friends.limit(10).fields(name)';

  FRESTResponse := TRESTResponse.Create(nil);
  FRESTRequest.Response := FRESTResponse;

  FTimer := TTimer.Create(nil);
  FTimer.Enabled := False;
  FTimer.Interval := 500;
  FTimer.OnTimer := OnFacebookTimerTimer;

  FButtonName := 'u_0_3';
  FEditName := 'feedform_user_message';

  FForm := TForm.Create(nil);
  FForm.BorderStyle := bsNone;
  FForm.BorderIcons := FForm.BorderIcons - [biSystemMenu, biMinimize, biSystemMenu];
  FForm.ClientHeight := 0; FForm.ClientWidth := 0;
  FForm.Hide;

  FWebBrowser := TWebBrowser.Create(nil);
  FWebBrowser.OnDocumentComplete := FaceBookDocumentComplete;
  FWebBrowser.Height := 0; FWebBrowser.Width := 0;
  TWinControl(FWebBrowser).Parent := FForm;
end;

destructor TFacebookHandle.Destroy;
begin
  FreeAndNil(FWebBrowser);
  FreeAndNil(FForm);
  FreeAndNil(FRestResponse);
  FreeAndNil(FRESTRequest);
  FreeAndNil(FRESTClient);
  FreeAndNil(FAuth2);
  inherited;
end;

{ TTwitterHandle }

constructor TTwitterHandle.Create;
begin
  inherited;
  FAuth1 := TOAuth1Authenticator.Create(nil);
  FAuth1.AccessTokenEndpoint := 'https://api.twitter.com/oauth/access_token';
  FAuth1.AuthenticationEndpoint := 'https://api.twitter.com/oauth/authenticate';
  FAuth1.RequestTokenEndpoint := 'https://api.twitter.com/oauth/request_token';

  FRESTClient := TRESTClient.Create('');
  FRESTClient.Authenticator := FAuth1;
  FRESTClient.Accept := 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';
  FRESTClient.HandleRedirects := True;

  FRESTRequest := TRESTRequest.Create(nil);
  FRESTRequest.Client := FRESTClient;
  FRESTRequest.Method := TRESTRequestMethod.rmGET;
  FRESTRequest.SynchronizedEvents := False;

  FRESTResponse := TRESTResponse.Create(nil);
  FRESTRequest.Response := FRESTResponse;

  FTimer := TTimer.Create(nil);
  FTimer.Enabled := False;
  FTimer.Interval := 1000;
  FTimer.OnTimer := OnTwitterTimerTimer;

end;

destructor TTwitterHandle.Destroy;
begin
  FreeAndNil(FRestResponse);
  FreeAndNil(FRESTRequest);
  FreeAndNil(FRESTClient);
  FreeAndNil(FAuth1);
  FreeAndNil(FTimer);
  inherited;
end;

end.
