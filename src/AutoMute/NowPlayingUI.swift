import Foundation

enum NowPlayingUI {
    static func togglePlayPause() {
        let script = """
        tell application "System Events"
          set targetProcesses to {"ControlCenter", "SystemUIServer"}
          repeat with procName in targetProcesses
            if exists process procName then
              tell process procName
                if exists menu bar 1 then
                  set theBar to menu bar 1
                  if exists (first menu bar item of theBar whose description is "Now Playing") then
                    set npItem to first menu bar item of theBar whose description is "Now Playing"
                  else if exists (first menu bar item of theBar whose description is "正在播放") then
                    set npItem to first menu bar item of theBar whose description is "正在播放"
                  else
                    set npItem to missing value
                  end if

                  if npItem is not missing value then
                    click npItem
                    delay 0.08
                    if exists window 1 then
                      set w to window 1
                      if exists (first button of w whose description is "暂停") then
                        click (first button of w whose description is "暂停")
                      else if exists (first button of w whose description is "播放") then
                        click (first button of w whose description is "播放")
                      else if exists (first button of w whose description is "Pause") then
                        click (first button of w whose description is "Pause")
                      else if exists (first button of w whose description is "Play") then
                        click (first button of w whose description is "Play")
                      end if
                    end if
                    delay 0.05
                    click npItem
                    return
                  end if
                end if
              end tell
            end if
          end repeat
        end tell
        """

        var error: NSDictionary?
        let appleScript = NSAppleScript(source: script)
        _ = appleScript?.executeAndReturnError(&error)
        if let error {
            Log.info("NowPlayingUI: script error: \(error)")
        } else {
            Log.info("NowPlayingUI: toggled")
        }
    }
}
