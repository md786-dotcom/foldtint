import Testing
@testable import FoldtintKit

struct ColorNameTests {
    @Test(arguments: [
        (ColorName.gray, 1),
        (ColorName.green, 2),
        (ColorName.purple, 3),
        (ColorName.blue, 4),
        (ColorName.yellow, 5),
        (ColorName.red, 6),
        (ColorName.orange, 7),
    ])
    func tagIndexes(_ color: ColorName, _ index: Int) {
        #expect(color.tagColorIndex == index)
    }

    @Test func defaultColorIsPurple() {
        #expect(ColorName.defaultColor == .purple)
    }

    @Test func argumentIsCaseInsensitive() {
        #expect(ColorName(argument: "Purple") == .purple)
        #expect(ColorName(argument: "RED") == .red)
        #expect(ColorName(argument: "nope") == nil)
    }

    @Test func allCasesCountIsSeven() {
        #expect(ColorName.allCases.count == 7)
    }
}
