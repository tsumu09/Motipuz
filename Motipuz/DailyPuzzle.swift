//
//  DailyPuzzle.swift
//  Motipuz
//
//  Created by 高橋紬季 on 2025/10/15.
//

import Foundation

struct DailyPuzzle: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var tasks: [Task]
    var imageData: Data?
}
