//
//  TaskManager.swift
//  Motipuz
//
//  Created by 高橋紬季 on 2025/10/15.
//

import Foundation
import UIKit

final class TaskManager {
    static let shared = TaskManager()
    private init() {}
    var dailyResults: [DailyResult] = []
    var dailyPuzzle: DailyPuzzle = TaskManager.loadTodayPuzzle()
    
    var totalValue: Int {
        dailyPuzzle.tasks.map { $0.value }.reduce(0, +)
    }
    
    var completedValue: Int {
        dailyPuzzle.tasks.filter { $0.isDone }.map { $0.value }.reduce(0, +)
    }
    
    var gridSize: Int {
        switch totalValue {
        case 0..<50: return 3
        case 50..<100: return 4
        default: return 5
        }
    }
    
    func addTask(_ task: Task) {
        dailyPuzzle.tasks.append(task)
        save()
    }
    
    func getTasks() -> [Task] {
        return dailyPuzzle.tasks
    }
    
    func toggleTask(id: UUID) {
        if let index = dailyPuzzle.tasks.firstIndex(where: { $0.id == id }) {
            // 画像更新は「配置が外れた時だけ」にする（isDoneだけでは変えない）
                        let wasPlaced = dailyPuzzle.tasks[index].isPlaced
            dailyPuzzle.tasks[index].isDone.toggle()
            if !dailyPuzzle.tasks[index].isDone {
                            dailyPuzzle.tasks[index].isPlaced = false
                        }
            if wasPlaced && !dailyPuzzle.tasks[index].isPlaced {
                            updateImageDataForDailyPuzzle()
                        } else {
                            save()
                        }
        }
    }
    
    static func key(from date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }
    
    func save() {
            let key = TaskManager.key(from: dailyPuzzle.date)
            if let data = try? JSONEncoder().encode(dailyPuzzle) {
                UserDefaults.standard.set(data, forKey: key)
            }
        }
    
    var goalValue: Int {
        get {
            UserDefaults.standard.integer(forKey: "dailyGoalValue") // なければ0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "dailyGoalValue")
        }
    }

    
    static func loadTodayPuzzle() -> DailyPuzzle {
            let today = Calendar.current.startOfDay(for: Date())
            let key = key(from: today)

            if let data = UserDefaults.standard.data(forKey: key),
               let puzzle = try? JSONDecoder().decode(DailyPuzzle.self, from: data) {
                return puzzle
            }

            return DailyPuzzle(
                date: today,
                tasks: [],
                imageData: nil
            )
        }

    
    static func loadPuzzle(for date: Date) -> DailyPuzzle {
            let key = key(from: date)

            if let data = UserDefaults.standard.data(forKey: key),
               let puzzle = try? JSONDecoder().decode(DailyPuzzle.self, from: data) {
                return puzzle
            }

            return DailyPuzzle(
                date: date,
                tasks: [],
                imageData: nil
            )
        }
    func markPlaced(taskID: UUID) {
        if let index = dailyPuzzle.tasks.firstIndex(where: { $0.id == taskID }) {
            dailyPuzzle.tasks[index].isPlaced = true
            // ピースを置いたら、進捗画像を作り直して保存する
                       updateImageDataForDailyPuzzle()
        }
    }
    
    func saveDailyResult(date: Date, isPerfect: Bool) {
        var results = loadDailyResults()

        // 同じ日のデータがあれば削除（上書き用）
        results.removeAll {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }

        let newResult = DailyResult(date: date, isPerfect: isPerfect)
        results.append(newResult)

        if let data = try? JSONEncoder().encode(results) {
            UserDefaults.standard.set(data, forKey: "dailyResults")
        }
    }
    
    func loadDailyResults() -> [DailyResult] {
        guard let data = UserDefaults.standard.data(forKey: "dailyResults"),
              let results = try? JSONDecoder().decode([DailyResult].self, from: data)
        else {
            return []
        }
        return results
    }
    private func save(_ results: [DailyResult]) {
            if let data = try? JSONEncoder().encode(results) {
                UserDefaults.standard.set(data, forKey: "dailyResults")
            }
        }
    func checkYesterdayResult() {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return }

        let yesterdayPuzzle = TaskManager.loadPuzzle(for: yesterday)
        let isPerfect = yesterdayPuzzle.tasks.allSatisfy { $0.isDone }

        saveDailyResult(date: yesterday, isPerfect: isPerfect)
        print(loadDailyResults())
    }
    // その日の画像データを「進捗 or ガイド」で作り直す
       private func updateImageDataForDailyPuzzle() {
           guard !dailyPuzzle.tasks.isEmpty else {
               dailyPuzzle.imageData = nil
               save()
               NotificationCenter.default.post(name: .puzzleImageUpdated, object: nil)
               return
           }

           let hasPlaced = dailyPuzzle.tasks.contains { $0.isPlaced }
           let image = hasPlaced
               ? makePuzzleProgressImage(tasks: dailyPuzzle.tasks, size: 300)
               : makePuzzleGuideImage(tasks: dailyPuzzle.tasks, size: 300)
           dailyPuzzle.imageData = image.pngData()
           save()
           // カレンダー側に「画像が更新されたよ」と知らせる
           NotificationCenter.default.post(name: .puzzleImageUpdated, object: nil)
       }
}
extension TaskManager {
    func perfectCount(for month: Date) -> Int {
        let calendar = Calendar.current
        let results = loadDailyResults()

        return results.filter {
            calendar.isDate($0.date, equalTo: month, toGranularity: .month)
            && $0.isPerfect
        }.count
    }
}
