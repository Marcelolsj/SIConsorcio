unit Util.UConfiguracoes;

interface

type
  TConfiguracoes = class
  private
    FRestContext: string;
    FContext: string;
    FPort: Integer;
    FHostName: string;
  public
    property HostName: string read FHostName write FHostName;
    property Context: string read FContext write FContext;
    property RestContext: string read FRestContext write FRestContext;
    property Port: Integer read FPort write FPort;
  end;

implementation

end.
