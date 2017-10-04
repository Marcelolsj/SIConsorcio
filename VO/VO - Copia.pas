unit VO;

interface

uses
  Classes, SysUtils, Generics.Collections, System.JSON;

type
  TVO = class(TPersistent)
  public
    constructor Create; overload; virtual;
    procedure SetValuesFromJSON(Obj: TJSONValue);
  end;

  TClassVO = class of TVO;

implementation

uses
  System.Rtti, Util.Atributos;

constructor TVO.Create;
begin
  inherited Create;
end;

procedure TVO.SetValuesFromJSON(Obj: TJSONValue);
var
  vContexto : TRttiContext;
  vTipo: TRttiType;
  vPropriedade: TRttiProperty;
  vAtributo: TCustomAttribute;
  JSONObj: TJSONObject;
begin
  try
    if Obj is TJSONObject then
      JSONObj := Obj as TJSONObject
    else if Obj is TJSONArray then
      JSONObj := TJSONArray(Obj).Items[0] as TJSONObject;

    vContexto := TRttiContext.Create;
    vTipo     := vContexto.GetType(Self.ClassType);

    for vPropriedade in vTipo.GetProperties do
    begin
      for vAtributo in vPropriedade.GetAttributes do
      begin
        try
          if vAtributo is TId then
          begin
            if JSONObj.GetValue(TId(vAtributo).Name) is TJSONString then
            begin
              try
                vPropriedade.SetValue(Self, StrToInt(TJSONString(JSONObj.GetValue(TId(vAtributo).Name)).Value));
              except
                vPropriedade.SetValue(Self, TJSONString(JSONObj.GetValue(TId(vAtributo).Name)).Value);
              end;
            end
            else if JSONObj.GetValue(TId(vAtributo).Name) is TJSONNumber then
              vPropriedade.SetValue(Self, TJSONNumber(JSONObj.GetValue(TId(vAtributo).Name)).Value)
            else
              vPropriedade.SetValue(Self, JSONObj.GetValue(TId(vAtributo).Name).Value);
          end
          else if vAtributo is TColumn then
            vPropriedade.SetValue(Self, JSONObj.GetValue(TColumn(vAtributo).Name).Value);
        except
        end;
      end;
    end;
  except
    on e: Exception do
      raise Exception.Create('Erro ao pegar os dados do objeto JSON.' + sLineBreak + e.Message);
  end;
end;

end.
