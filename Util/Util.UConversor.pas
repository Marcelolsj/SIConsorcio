unit Util.UConversor;

interface

uses Classes, DBXJSON, SysUtils, System.JSON, Data.DB;

type
  TConversor = class
  private
    class function ExtractValueFromJSONObjectStream(pStream: TStringStream): string;
    class function ExtractValueFromJSONPairStr(pStr: string): string;
  public
    class function JSONObjectStreamToBoolean(pStream: TStringStream): Boolean;
    class function JSONObjectStreamToInteger(pStream: TStringStream): Integer;
    class function JSONPairStrToBoolean(pStr: string): Boolean;
    class function JSONArrayStreamToJSONArray(pStream: TStringStream): TJSONArray;
    class function ListJSONArrayStreamToJSONArray(pStream: TStringStream; pIdx: Integer): TJSONArray;
    class function DataSetToJSON(DataSet : TDataset; OnlyRow: Boolean) : TJSONArray;
    class function JSONToDataSet(JSON: TJSONObject; DataSet: TDataSet): TDataSet;
  end;

implementation

{ TConversor }

class function TConversor.DataSetToJSON(DataSet: TDataset; OnlyRow: Boolean): TJSONArray;
var
  JObject : TJSONObject;
  Field: TField;
begin
  Result := TJSONArray.Create;

  if OnlyRow then
  begin
    JObject := TJSONObject.Create;
    for Field in DataSet.Fields do
      JObject.AddPair(Field.FieldName, TJSONString.Create(Field.AsString));

    Result.Add(JObject);
  end
  else
  begin
    DataSet.First;
    while not DataSet.Eof do
    begin
      JObject := TJSONObject.Create;
      for Field in DataSet.Fields do
        JObject.AddPair(Field.FieldName, TJSONString.Create(Field.AsString));

      Result.Add(JObject);
      DataSet.Next;
    end;
  end;
end;

class function TConversor.ExtractValueFromJSONObjectStream(pStream: TStringStream): string;
var
  jObj: TJSONObject;
begin
  jObj := TJSONObject.Create;
  try
    jObj.Parse(pStream.Bytes, 0);

    Result := jObj.Pairs[0].JsonValue.ToString;

    //Remove Couchetes
    Result := Copy(Result,3,Length(Result)-4);
  finally
    jObj.Free;
  end;
end;

class function TConversor.ExtractValueFromJSONPairStr(pStr: string): string;
var
  I: Integer;
  Valor: string;
begin
  Valor := pStr;

  I := Pos('[',Valor);
  Delete(Valor,1,I);

  I := Pos(']',Valor);
  Result := Copy(Valor,1,I-1);
end;

class function TConversor.JSONObjectStreamToBoolean(pStream: TStringStream): Boolean;
begin
  Result := StrToBoolDef(ExtractValueFromJSONObjectStream(pStream),False);
end;

class function TConversor.JSONObjectStreamToInteger(
  pStream: TStringStream): Integer;
begin
  Result := StrToIntDef(ExtractValueFromJSONObjectStream(pStream),-1);
end;

class function TConversor.JSONPairStrToBoolean(pStr: string): Boolean;
begin
  Result := StrToBoolDef(ExtractValueFromJSONPairStr(pStr),False);
end;

class function TConversor.JSONToDataSet(JSON: TJSONObject; DataSet: TDataSet): TDataSet;
var
  I, J: Integer;
  JSONArray: TJSONArray;
  JSONValue: TJSONValue;
  JSONPair: TJSONPair;
  Field: TField;
begin
  JSONArray := JSON.Pairs[0].JsonValue as TJSONArray;
  if JSONArray.Count > 0 then
  begin
    JSONArray := JSONArray.Items[0] as TJSONArray;
    for I := 0 to JSONArray.Count - 1 do
    begin
      JSONValue := JSONArray.Items[I];

      if JSONValue is TJSONObject then
      begin
        for J := 0 to TJSONObject(JSONValue).Count - 1 do
        begin
          JSONPair := TJSONObject(JSONValue).Pairs[J];
          Field := DataSet.FindField(JSONPair.JsonString.Value);
          if Field <> nil then
          begin
            if not (DataSet.State in dsEditModes) then
              DataSet.Append;

            if JSONPair.JsonValue is TJSONString then
              Field.AsString := TJSONString(JSONPair.JsonValue).Value
            else if JSONPair.JsonValue is TJSONNumber then
              Field.AsFloat := TJSONNumber(JSONPair.JsonValue).AsDouble;
          end;
        end;
      end;
      if DataSet.State in dsEditModes then
        DataSet.Post;
    end;
  end;

  Result := DataSet;
end;

class function TConversor.JSONArrayStreamToJSONArray(pStream: TStringStream): TJSONArray;
var
  jObj: TJSONObject;
  jPair: TJSONPair;
begin
  jObj := TJSONObject.Create;
  try
    jObj.Parse(pStream.Bytes, 0);
    jPair := jObj.Pairs[0];

    Result := (TJSONArray(jPair.JsonValue).Items[0] as TJSONArray).Clone as TJSONArray;
  finally
    jObj.Free;
  end;
end;

class function TConversor.ListJSONArrayStreamToJSONArray(pStream: TStringStream; pIdx: Integer): TJSONArray;
var
  A: TJSONArray;
begin
  A := JSONArrayStreamToJSONArray(pStream);
  try
    Result := A.Items[pIdx].Clone as TJSONArray;
  finally
    A.Free;
  end;
end;

end.
