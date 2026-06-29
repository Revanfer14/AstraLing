//
//  Sound.swift
//  AstraLing
//
//  Created by Rasya Devan on 29/06/26.
//

import AVFoundation
import AudioToolbox

enum Sound {
    private static var players: [String: AVAudioPlayer] = [:]

    static func success()      { play("success", systemFallback: 1407) }
    static func notification() { play("alert",   systemFallback: 1007) }
    static func error()        { play("error",   systemFallback: 1257) }

    private static func play(_ name: String, systemFallback id: SystemSoundID) {
        for ext in ["caf", "wav", "mp3", "aiff"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                if let player = try? AVAudioPlayer(contentsOf: url) {
                    player.prepareToPlay()
                    player.play()
                    players[name] = player
                    return
                }
                break
            }
        }
        AudioServicesPlaySystemSound(id)
    }
}
