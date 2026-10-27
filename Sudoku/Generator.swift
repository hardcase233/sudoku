import Foundation

enum Difficulty: String, CaseIterable, Identifiable {
    case easy = "Easy", medium = "Medium", hard = "Hard"
    var id: String { rawValue }
    var emptyRange: ClosedRange<Int> {
        switch self { case .easy: return 36...40; case .medium: return 45...50; case .hard: return 52...56 }
    }
}

struct Puzzle {
    let givens: [Int]
    let solution: [Int]
}

enum Generator {
    static func ok(_ b: [Int], _ i: Int, _ n: Int) -> Bool {
        let r = i / 9, c = i % 9, br = r / 3 * 3, bc = c / 3 * 3
        for k in 0..<9 {
            if b[r*9+k] == n || b[k*9+c] == n || b[(br + k/3)*9 + bc + k%3] == n { return false }
        }
        return true
    }

    static func fill(_ b: inout [Int]) -> Bool {
        guard let i = b.firstIndex(of: 0) else { return true }
        for n in (1...9).shuffled() where ok(b, i, n) {
            b[i] = n
            if fill(&b) { return true }
        }
        b[i] = 0
        return false
    }

    /// Counts solutions, stopping at `cap`. Picks the empty cell with fewest candidates.
    static func count(_ b: inout [Int], cap: Int = 2) -> Int {
        var best = -1, bestC: [Int] = []
        for i in 0..<81 where b[i] == 0 {
            let cands = (1...9).filter { ok(b, i, $0) }
            if cands.isEmpty { return 0 }
            if best < 0 || cands.count < bestC.count { best = i; bestC = cands; if cands.count == 1 { break } }
        }
        if best < 0 { return 1 }
        var total = 0
        for n in bestC {
            b[best] = n
            total += count(&b, cap: cap - total)
            b[best] = 0
            if total >= cap { break }
        }
        return total
    }

    /// Returns a puzzle with a guaranteed unique solution. Tries to reach a random target
    /// in the difficulty range; if it can't within the time budget, keeps the attempt with most empties.
    static func generate(_ d: Difficulty, budget: TimeInterval = 2.0) -> Puzzle {
        let target = Int.random(in: d.emptyRange)
        let start = Date()
        var best: [Int] = [], bestSolution: [Int] = []
        var bestEmpty = -1
        repeat {
            var solved = [Int](repeating: 0, count: 81)
            _ = fill(&solved)
            var p = solved, empty = 0
            for i in (0..<81).shuffled() where empty < target {
                let v = p[i]; p[i] = 0
                var t = p
                if count(&t) == 1 { empty += 1 } else { p[i] = v }
            }
            if empty > bestEmpty { best = p; bestSolution = solved; bestEmpty = empty }
        } while bestEmpty < target && Date().timeIntervalSince(start) < budget
        return Puzzle(givens: best, solution: bestSolution)
    }
}
