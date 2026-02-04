//
//  Task.swift
//  Motipuz
//
//  Created by 高橋紬季 on 2025/10/15.
//

import Foundation

struct Task: Codable, Identifiable {
    var id = UUID()
    var title: String
    var importance: Int     // 1〜3
    var weight: Int         // 1〜10
    var isDone: Bool = false
    
    var value: Int { importance * weight }
    var isPlaced: Bool

}

