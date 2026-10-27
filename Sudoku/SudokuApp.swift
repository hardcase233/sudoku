import SwiftUI

@main
struct SudokuApp: App {
    var body: some Scene {
        WindowGroup { ContentView().preferredColorScheme(.dark) }
    }
}

let gold = Color(red: 0.83, green: 0.69, blue: 0.22)

final class Game: ObservableObject {
    static let puzzle: [Int] = [
        5,3,0,0,7,0,0,0,0,
        6,0,0,1,9,5,0,0,0,
        0,9,8,0,0,0,0,6,0,
        8,0,0,0,6,0,0,0,3,
        4,0,0,8,0,3,0,0,1,
        7,0,0,0,2,0,0,0,6,
        0,6,0,0,0,0,2,8,0,
        0,0,0,4,1,9,0,0,5,
        0,0,0,0,8,0,0,7,9]
    @Published var cells = Game.puzzle
    @Published var selected: Int? = nil
    @Published var error: String? = nil
    @Published var errorCell: Int? = nil

    func isGiven(_ i: Int) -> Bool { Game.puzzle[i] != 0 }
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

    func reset() { cells = Game.puzzle; selected = nil; error = nil; errorCell = nil }
}

struct ContentView: View {
    @StateObject var g = Game()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 18) {
                Text("SUDOKU").font(.system(size: 30, weight: .heavy)).tracking(6).foregroundColor(gold)
                Text(g.solved ? "Solved!" : (g.error ?? " "))
                    .font(.headline)
                    .foregroundColor(g.solved ? gold : .red)
                    .frame(height: 22)
                board
                pad
                Button("Reset") { g.reset() }
                    .font(.headline).foregroundColor(.black)
                    .padding(.horizontal, 40).padding(.vertical, 10)
                    .background(gold).cornerRadius(8)
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
