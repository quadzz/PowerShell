$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (!($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
    Write-Output "[X] [X] [X] [X] [X] [X] Will not run scripts, powershell needs to be in admin mode! [X] [X] [X] [X] [X] [X] [X] [X] ";
}
else {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned;

    if (!(Test-Path $profile)) {
        New-Item -ItemType File -Path $profile -Force;
    }
    
    #Prepare modules
    if (!(Get-Module -Name "oh-my-posh")) {
        Install-Module oh-my-posh;
    }
    else {
        Write-Output "oh-my-posh is already installed!";
    }
    
    if (!(Get-Module -Name "terminal-icons")) {
        Install-Module -Name Terminal-Icons -Repository PSGallery;
    }
    else {
        Write-Output "terminal-icons are already installed";
    }
    
    #THEME
    $path = Split-Path $profile -Parent;
    $json = Join-Path $path "theme.json";
    Write-Output "Will set theme path to $json";
    
    $themeContent = "'" + '{
        "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
        "blocks": [
          {
            "type": "prompt",
            "alignment": "left",
            "segments": [
              {
                "type": "os",
                "style": "diamond",
                "foreground": "#26C6DA",
                "background": "#546E7A",
                "properties": {
                  "postfix": " \uE0B1",
                  "macos": "mac"
                },
                "leading_diamond": "\uE0c5",
                "trailing_diamond": "\uE0B0"
              },
              {
                "type": "session",
                "style": "powerline",
                "foreground": "#26C6DA",
                "background": "#546E7A",
                "powerline_symbol": "\uE0B0"
              },
              {
                "type": "battery",
                "style": "powerline",
                "powerline_symbol": "\uE0B0",
                "foreground": "#193549",
                "background": "#a2beef",
                "properties": {
                  "battery_icon": "\f583",
                  "color_background": true,
                  "charged_color": "#0476d0",
                  "charging_color": "#00D100",
                  "discharging_color": "#FFCD58",
                  "postfix": "\uF295 \uf583 "
                }
              },
              {
                "type": "path",
                "style": "powerline",
                "powerline_symbol": "\uE0B0",
                "foreground": "#193549",
                "background": "#14c2dd",
                "properties": {
                  "prefix": " \uE5FF ",
                  "style": "folder"
                }
              },
              {
                "type": "git",
                "style": "powerline",
                "powerline_symbol": "\uE0B0",
                "foreground": "#193549",
                "background": "#a2c4e0",
                "properties": {
                  "display_stash_count": true,
                  "display_upstream_icon": true
                }
              },
              {
                "type": "node",
                "style": "powerline",
                "powerline_symbol": "\uE0B0",
                "foreground": "#ffffff",
                "background": "#6CA35E",
                "properties": {
                  "prefix": " \uE718 "
                }
              },
              {
                "type": "root",
                "style": "powerline",
                "powerline_symbol": "\uE0B0",
                "foreground": "#193549",
                "background": "#ffff66"
              },
              {
                "type": "kubectl",
                "style": "powerline",
                "powerline_symbol": "\uE0B0",
                "foreground": "#ffffff",
                "background": "#0077c2",
                "properties": {
                  "prefix": " \uFD31 ",
                  "template": "{{.Context}} :: {{if .Namespace}}{{.Namespace}}{{else}}default{{end}}"
                }
              },
              {
                "type": "exit",
                "style": "diamond",
                "foreground": "#ffffff",
                "background": "#007800",
                "leading_diamond": "<transparent, #007800>\uE0B0</>",
                "trailing_diamond": "\uE0b0",
                "properties": {
                  "display_exit_code": false,
                  "always_enabled": true,
                  "error_color": "#f1184c",
                  "color_background": true,
                  "prefix": " \ufc8d"
                }
              }
            ]
          },
          {
            "type": "prompt",
            "alignment": "left",
            "newline": true,
            "segments": [
              {
                "type": "text",
                "style": "plain",
                "foreground": "#007ACC",
                "properties": {
                  "prefix": "",
                  "text": "\u279C"
                }
              }
            ]
          }
        ],
        "final_space": true
      }' + "'";
    $content = @("$themeContent | Set-Content `"$json`"", "Import-Module oh-my-posh", "Set-PoshPrompt -Theme `"$json`"", "Import-Module -Name Terminal-Icons");
    $content | Set-Content $profile;
    
    . $profile;
}
