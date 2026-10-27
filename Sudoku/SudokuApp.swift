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
    @Published var cells: [Int]
    @Published var difficulty: Difficulty = .easy
    @Published var selectedDifficulty: Difficulty = .easy
    @Published var generating = false

    init() {
        let p = Generator.generate(.easy)
        givens = p; cells = p
    }

    func newPuzzle() {
        guard !generating else { return }
        generating = true
        let d = selectedDifficulty
        DispatchQueue.global(qos: .userInitiated).async {
            let p = Generator.generate(d)
            DispatchQueue.main.async {
                self.givens = p; self.cells = p; self.difficulty = d
                self.selected = nil; self.error = nil; self.errorCell = nil
                self.generating = false
            }
        }
    }
    @Published var selected: Int? = nil
    @Published var error: String? = nil
    @Published var errorCell: Int? = nil

    func isGiven(_ i: Int) -> Bool { givens[i] != 0 }
    var solved: Bool { !cells.contains(0) }

    func related(_ a: Int, _ b: Int) -> Bool {
        let (ra, ca, rb, cb) = (a/9, a%9, b/9, b%9)
        return ra == rb || ca == cb || (ra/3 == rb/3 && ca/3 == cb/3)
    }

    func place(_ n: Int) {
        guard let s = selected, !isGiven(s) else { return }
        if n == 0 { cells[s] = 0; return }
        if (0..<81).contains(where: { $0 != s && cells[$0] == n && related($0, s) }) {
            flash("\(n) already in this row, column, or box", s); return
        }
        cells[s] = n
    }

    func flash(_ msg: String, _ i: Int) {
        error = msg; errorCell = i
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.error = nil; self?.errorCell = nil
        }
    }

    func reset() { cells = givens; selected = nil; error = nil; errorCell = nil }
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
                Text(g.solved ? "Solved!" : (g.error ?? " "))
                    .font(.headline)
                    .foregroundColor(g.solved ? gold : .red)
                    .frame(height: 22)
                board
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

    func bg(_ i: Int) -> Color {
        if g.errorCell == i { return .red.opacity(0.6) }
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
                ForEach(0..<81, id: \.self) { i in
                    let v = g.cells[i]
                    Text(v == 0 ? "" : "\(v)")
                        .font(.system(size: c * 0.55, weight: g.isGiven(i) ? .heavy : .regular))
                        .foregroundColor(g.isGiven(i) ? .white : gold)
                        .frame(width: c, height: c)
                        .background(bg(i))
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
