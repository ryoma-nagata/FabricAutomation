## 手順

1. [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fryoma-nagata%2FFabricAutomation%2Fmain%2Fsource%2Ffabricautomation.json)をデプロイします。（ロジックアプリが有効済みでデプロイされます）
actionパラメータでは、ロジックアプリの実行するいずれかの操作を指定できます  
停止したい場合：suspend  
開始したい場合：resume  
SKU変更したい場合：scaling  
※このロジックアプリでは実行するのは上記いずれか1つの操作のみとなります。改修するか、操作ごとにロジックアプリをデプロイしてください
![](.image/2023-11-16-12-37-14.png)

2. 作成されたlogic apps を Fabric Capacity のAzure RBAC 共同作成者に割り当て
![](.image/2023-11-16-12-38-43.png)

3. 必要に応じて、デザイナーから各種のパラメータを調整可能
   1. 実行時刻
   ![Alt text](.image/image.png)
   2. パラメータ内容
   ![](.image/2023-11-16-12-08-58.png)
