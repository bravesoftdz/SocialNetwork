program SocialNetworks;

uses
  Vcl.Forms,
  UnitMain in 'UnitMain.pas' {frmMain},
  REST.Authenticator.OAuth.WebForm.Win {frm_OAuthWebForm},
  UnitHandle in 'UnitHandle.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
