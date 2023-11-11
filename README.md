## Functions

### Get-Env

```powershell
Get-Env -Name foo -Scope Machine
```


### Set-Env

```powershell
Set-Env -Name foo -Value bar -Scope Process -Oper Override
```

```powershell
Set-Env -Name foo -Value bar -Scope Process -Oper AppendFirst
```

```powershell
Set-Env -Name foo -Value bar -Scope Process -Oper AppendLast
```



### Sync-Env

```powershell
Sync-Env -Name foo -From User,Machine -To Process
```
