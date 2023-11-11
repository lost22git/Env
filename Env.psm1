<#
  .SYNOPSIS
  查询环境变量值
  
  .EXAMPLE
  Get-Env -Name Path -Scope Machine

  .EXAMPLE
  Get-Env -Name Path -Scope User
#>
function Get-Env
{
  [CmdletBinding()]
  [OutputType([string])]
  param(

    # 环境变量名
    [Parameter(Mandatory)]
    [string]$Name,

    # 环境变量作用范围 Machine or User or Process
    [Parameter(Mandatory)]
    [System.EnvironmentVariableTarget]$Scope
  )

  return [System.Environment]::GetEnvironmentVariable($Name, $Scope)
}



enum SetEnvOp
{
  Override
  AppendFirst
  AppendLast
}
<#
    .SYNOPSIS
    设置环境变量 (自动去重)

    .EXAMPLE
    Set-Env -Name foo -Value baz -Scope Process -Oper AppendFirst

    .EXAMPLE
    Set-Env -Name foo -Value abc -Scope Process -Oper AppendLast

    .EXAMPLE
    Set-Env -Name foo -Value "" -Scope Process -Oper Override 
#>
function Set-Env
{
  [CmdletBinding()]
  param(
    # 环境变量名
    [Parameter(Mandatory)]
    [string]$Name,

    # 环境变量值
    [Parameter(Mandatory, ValueFromPipeline)]
    [AllowEmptyString()]
    [string]$Value,

    # 环境变量作用范围 Machine or User or Process
    [Parameter(Mandatory)]
    [System.EnvironmentVariableTarget]$Scope,

    # 操作
    [Parameter(Mandatory)]
    [SetEnvOp]$Oper
  )

  $oldValue = [Environment]::GetEnvironmentVariable($Name, $Scope)

  $newValue = if (($null -eq $oldValue) -or ($Oper -eq [SetEnvOp]::Override))
  {
    $Value
  } elseif ($Oper -eq [SetEnvOp]::AppendLast)
  {
    "${oldValue};${Value}"
  } else
  {
    "${Value};${oldValue}"
  }

  $newValue = $newValue.Split(";", [StringSplitOptions]::RemoveEmptyEntries)
  | Select-Object -Unique
  | Join-String -Separator ";"

  if ($newValue -eq "")
  {
    $newValue = $null
  }

  [Environment]::SetEnvironmentVariable($Name, $newValue, $Scope)

  Write-Host "[Set-Env] in ${Scope}: $Name -> $newValue"
}



<#
  .SYNOPSIS
  同步环境变量值 (自动去重)

  .EXAMPLE
  Sync-Env -Name Path

  .EXAMPLE
  # equals to 'Sync-Env -Name Path'
  Sync-Env -Name Path -From User,Machine -To Process

  .EXAMPLE
  Sync-Env -Name Path -From Process,Machine,User -To Process
#>
function Sync-Env
{
  [CmdletBinding()]
  param(
    # env name
    [Parameter(Mandatory)]
    [string]$Name,

    # from env scopes (ordered)
    [Parameter()]
    [System.EnvironmentVariableTarget[]]$From = @([System.EnvironmentVariableTarget]::User, [System.EnvironmentVariableTarget]::Machine),
    
    # to env scope
    [Parameter()]
    [System.EnvironmentVariableTarget]$To = [System.EnvironmentVariableTarget]::Process
  )

  $newValue = $From | Select-Object -Unique 
  | ForEach-Object { [System.Environment]::GetEnvironmentVariable($Name, $_) } 
  | Join-String -Separator ";"
  
  Set-Env -Name $Name -Value $newValue -Scope $To -Oper Override
}
