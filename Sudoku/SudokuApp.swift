import SwiftUI

@main
struct SudokuApp: App {
    init() {
        let a = UISegmentedControl.appearance()
        a.selectedSegmentTintColor = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1)
        a.backgroundColor = UIColor(white: 0.12, alpha: 1)
        a.setTitleTextAttributes([.foregroundColor: UIColor.black, .font: UIFont.boldSystemFont(ofSize: 14)], for: .selected)
        a.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
    }
    var body: some Scene {
        WindowGroup { ContentView().preferredColorScheme(.dark) }
    }
}

let gold = Color(red: 0.83, green: 0.69, blue: 0.22)

final class Game: ObservableObject {
    @Published var givens: [Int]
    @Published var solution: [Int]
    @Published var cells: [Int]
    @Published var difficulty: Difficulty = .easy
    @Published var selectedDifficulty: Difficulty = .easy
    @Published var generating = false
    @Published var selected: Int? = nil

    init() {
        let p = Generator.generate(.easy)
        givens = p.givens; solution = p.solution; cells = p.givens
    }

    func newPuzzle() {
        guard !generating else { return }
        generating = true
        let d = selectedDifficulty
        DispatchQueue.global(qos: .userInitiated).async {
            let p = Generator.generate(d)
            DispatchQueue.main.async {
                self.givens = p.givens; self.solution = p.solution; self.cells = p.givens
                self.difficulty = d; self.selected = nil
                self.generating = false
            }
        }
    }

    func isGiven(_ i: Int) -> Bool { givens[i] != 0 }

    static func sameRow(_ a: Int, _ b: Int) -> Bool { a / 9 == b / 9 }
    static func sameCol(_ a: Int, _ b: Int) -> Bool { a % 9 == b % 9 }
    static func sameBox(_ a: Int, _ b: Int) -> Bool { a / 27 == b / 27 && (a % 9) / 3 == (b % 9) / 3 }

    func related(_ a: Int, _ b: Int) -> Bool { Game.sameRow(a, b) || Game.sameCol(a, b) || Game.sameBox(a, b) }

    /// Every cell whose value duplicates a peer (row, column, or box). Recomputed live from `cells`.
    var conflicts: Set<Int> {
        var out = Set<Int>()
        for a in 0..<81 where cells[a] != 0 {
            for b in (a + 1)..<81 where cells[b] == cells[a] && related(a, b) { out.insert(a); out.insert(b) }
        }
        return out
    }

    /// Message describing conflicts, preferring the selected cell.
    var conflictMessage: String? {
        let cs = conflicts
        guard !cs.isEmpty else { return nil }
        let focus = (selected.flatMap { cs.contains($0) ? $0 : nil }) ?? cs.sorted().first!
        let v = cells[focus]
        var kinds: [String] = []
        let peers = (0..<81).filter { $0 != focus && cells[$0] == v }
        if peers.contains(where: { Game.sameRow($0, focus) }) { kinds.append("row") }
        if peers.contains(where: { Game.sameCol($0, focus) }) { kinds.append("column") }
        if peers.contains(where: { Game.sameBox($0, focus) }) { kinds.append("box") }
        return "Conflict: \(v) repeats in " + kinds.joined(separator: ", ")
    }

    var solved: Bool { !cells.contains(0) && conflicts.isEmpty && cells == solution }

    func place(_ n: Int) {
        guard !solved, let s = selected, !isGiven(s) else { return }
        cells[s] = n   // conflicting entries are accepted and highlighted
    }

    func reset() { cells = givens; selected = nil }
}

struct ContentView: View {
    @StateObject var g = Game()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 18) {
                Text("SUDOKU").font(.system(size: 30, weight: .heavy)).tracking(6).foregroundColor(gold)
                HStack {
                    Text("DIFFICULTY").font(.caption.bold()).tracking(2).foregroundColor(.white.opacity(0.6))
                    Text(g.difficulty.rawValue.uppercased()).font(.caption.bold()).tracking(2).foregroundColor(gold)
                }
                Picker("Difficulty", selection: $g.selectedDifficulty) {
                    ForEach(Difficulty.allCases) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented)
                Text(g.solved ? "Puzzle complete" : (g.conflictMessage ?? " "))
                    .font(.headline)
                    .foregroundColor(g.solved ? gold : .red)
                    .frame(height: 22)
                board
                    .overlay(solvedBanner)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: g.solved)
                pad
                HStack(spacing: 14) {
                    Button { g.newPuzzle() } label: {
                        HStack(spacing: 6) {
                            if g.generating { ProgressView().tint(.black) }
                            Text(g.generating ? "Generating" : "New Puzzle")
                        }
                        .font(.headline).foregroundColor(.black)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(gold).cornerRadius(8)
                    }.disabled(g.generating)
                    Button { g.reset() } label: {
                        Text("Reset").font(.headline).foregroundColor(gold)
                            .padding(.horizontal, 28).padding(.vertical, 10)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(gold, lineWidth: 1.5))
                    }
                }
            }.padding()
        }
    }

    @ViewBuilder var solvedBanner: some View {
        if g.solved {
            VStack(spacing: 6) {
                Image(systemName: "star.fill").font(.system(size: 34)).foregroundColor(.black)
                Text("Solved!").font(.system(size: 40, weight: .heavy)).foregroundColor(.black)
                Text("New Puzzle or Reset to play again").font(.footnote.bold()).foregroundColor(.black.opacity(0.7))
            }
            .padding(.horizontal, 30).padding(.vertical, 20)
            .background(LinearGradient(colors: [gold, Color(red: 1, green: 0.85, blue: 0.4), gold],
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
            .cornerRadius(14)
            .shadow(color: gold.opacity(0.7), radius: 24)
            .transition(.scale(scale: 0.3).combined(with: .opacity))
        }
    }

    func bg(_ i: Int, _ cs: Set<Int>) -> Color {
        if cs.contains(i) { return .red.opacity(g.isGiven(i) ? 0.25 : 0.45) }
        if let s = g.selected {
            if s == i { return gold.opacity(0.55) }
            if g.related(s, i) { return Color.white.opacity(0.1) }
        }
        return .black
    }

    var board: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let c = side / 9
            ZStack(alignment: .topLeading) {
                let cs = g.conflicts
                ForEach(0..<81, id: \.self) { i in
                    let v = g.cells[i]
                    let bad = cs.contains(i)
                    Text(v == 0 ? "" : "\(v)")
                        .font(.system(size: c * 0.55, weight: g.isGiven(i) ? .heavy : .regular))
                        .foregroundColor(bad && !g.isGiven(i) ? .red : (g.isGiven(i) ? .white : gold))
                        .frame(width: c, height: c)
                        .background(bg(i, cs))
                        .overlay(Rectangle().stroke(Color.red, lineWidth: bad ? 2 : 0).padding(1.5))
                        .offset(x: CGFloat(i % 9) * c, y: CGFloat(i / 9) * c)
                        .onTapGesture { g.selected = i }
                }
                Path { p in
                    for k in 0...9 {
                        let x = CGFloat(k) * c
                        p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: side))
                        p.move(to: CGPoint(x: 0, y: x)); p.addLine(to: CGPoint(x: side, y: x))
                    }
                }.stroke(Color.white.opacity(0.3), lineWidth: 0.5).allowsHitTesting(false)
                Path { p in
                    for k in stride(from: 0, through: 9, by: 3) {
                        let x = CGFloat(k) * c
                        p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: side))
                        p.move(to: CGPoint(x: 0, y: x)); p.addLine(to: CGPoint(x: side, y: x))
                    }
                }.stroke(Color.white, lineWidth: 3).allowsHitTesting(false)
            }.frame(width: side, height: side)
        }.aspectRatio(1, contentMode: .fit)
    }

    var pad: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) { ForEach(1...5, id: \.self) { key($0) } }
            HStack(spacing: 8) {
                ForEach(6...9, id: \.self) { key($0) }
                Button { g.place(0) } label: {
                    Image(systemName: "delete.left").font(.title2)
                        .frame(width: 56, height: 50).foregroundColor(.white)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 1.5))
                }
            }
        }
    }

    func key(_ n: Int) -> some View {
        Button { g.place(n) } label: {
            Text("\(n)").font(.title2.bold()).foregroundColor(gold)
                .frame(width: 56, height: 50)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(gold, lineWidth: 1.5))
        }
    }
}
