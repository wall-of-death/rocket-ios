import UIKit

public enum Brand {
    public static func color(for color: Color) -> UIColor {
        switch color {
        case .brand(.primary):            return #colorLiteral(red: 0.2862745098, green: 0.631372549, blue: 0.9725490196, alpha: 1) // #49A1F8
        case .background(.primary):       return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) // #000000
        case .background(.button):        return #colorLiteral(red: 0.1098039216, green: 0.1098039216, blue: 0.1176470588, alpha: 1) // #1C1C1E
        case .background(.cell):          return #colorLiteral(red: 0.1098039216, green: 0.1098039216, blue: 0.1176470588, alpha: 1) // #1C1C1E
        case .background(.cellSelected):  return #colorLiteral(red: 0.2549019608, green: 0.2509803922, blue: 0.2705882353, alpha: 1) // #414045
        case .background(.navigationBar): return #colorLiteral(red: 0.1568627451, green: 0.1568627451, blue: 0.1607843137, alpha: 1) // #282829
        case .text(.primary):             return #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) // #FFFFFF
        case .text(.button):              return #colorLiteral(red: 0.2862745098, green: 0.631372549, blue: 0.9725490196, alpha: 1) // #49A1F8
        case .text(.link):                return #colorLiteral(red: 0.9176470588, green: 0.431372549, blue: 0.3411764706, alpha: 1) // #EA6E57
        }
    }

    public enum Color {

        case brand(BrandColor)
        case background(BackgroundColor)
        case text(TextColor)
        
        public enum BrandColor: CaseIterable {
            case primary
        }

        public enum BackgroundColor: CaseIterable {
            case primary, button, cell, cellSelected, navigationBar
        }
        public enum TextColor: CaseIterable {
            case primary, link, button
        }
    }
    
    static func font(for typography: Typography) -> UIFont {
        .systemFont(ofSize: fontSize(for: typography),
                    weight: fontWeight(for: typography))
    }

    private static func fontSize(for typography: Typography) -> CGFloat {
        switch typography {
        case .xxlarge, .xxlargeStrong:
            return 24.0
        case .xlarge, .xlargeStrong:
            return 20.0
        case .large, .largeStrong:
            return 17.0
        case .medium, .mediumStrong:
            return 15.0
        case .small, .smallStrong:
            return 14.0
        case .xsmall, .xsmallStrong:
            return 12.0
        case .xxsmall, .xxsmallStrong:
            return 11.0
        }
    }
    private static func fontWeight(for typography: Typography) -> UIFont.Weight {
        switch typography {
        case .xxlargeStrong, .xlargeStrong, .largeStrong, .mediumStrong, .smallStrong, .xsmallStrong, .xxsmallStrong:
            return .semibold
        case .xxlarge, .xlarge, .large, .medium, .small, .xsmall, .xxsmall:
            return .regular
        }
    }

    public enum Typography: String, CaseIterable {
        case xxlarge, xlarge, large,
             medium,
             small, xsmall, xxsmall,
             xxlargeStrong, xlargeStrong, largeStrong,
             mediumStrong,
             smallStrong, xsmallStrong, xxsmallStrong
    }
}

@available(*, deprecated)
struct style {
    enum color {
        case main
        case second
        case background
        case subBackground
        case sub

        func get() -> UIColor {
            switch self {
            case .main:
                return UIColor.white
            case .second:
                return UIColor.systemGreen
            case .background:
                return UIColor.black
            case .subBackground:
                return UIColor.darkGray
            case .sub:
                return UIColor.systemGray
            }
        }
    }

    //    一応書いとくけどIB内で設定するから使わない(迷ったら見てね的な)
    enum margin: Int {
        case box = 12
        case area = 16
        case letter = 8
    }

    enum font {
        case xlarge
        case large
        case regular
        case small

        func get() -> UIFont {
            switch self {
            case .xlarge:
                return UIFont.systemFont(ofSize: CGFloat(22), weight: UIFont.Weight(500))
            case .large:
                return UIFont.systemFont(ofSize: CGFloat(18), weight: UIFont.Weight(300))
            case .regular:
                return UIFont.systemFont(ofSize: CGFloat(14), weight: UIFont.Weight(100))
            case .small:
                return UIFont.systemFont(ofSize: CGFloat(10), weight: UIFont.Weight(100))
            }
        }
    }
}