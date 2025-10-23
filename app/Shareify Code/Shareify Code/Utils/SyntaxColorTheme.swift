import UIKit

struct SyntaxColorTheme {
    let keyword: UIColor
    let string: UIColor
    let comment: UIColor
    let number: UIColor
    let type: UIColor
    let function: UIColor
    let attribute: UIColor
    let directive: UIColor
    let plainText: UIColor
    
    static let xcodeDefault = SyntaxColorTheme(
        keyword: UIColor(red: 0.976, green: 0.286, blue: 0.573, alpha: 1.0),
        string: UIColor(red: 0.988, green: 0.412, blue: 0.365, alpha: 1.0),
        comment: UIColor(red: 0.420, green: 0.475, blue: 0.518, alpha: 1.0),
        number: UIColor(red: 0.820, green: 0.573, blue: 0.976, alpha: 1.0),
        type: UIColor(red: 0.212, green: 0.784, blue: 0.784, alpha: 1.0),
        function: UIColor(red: 0.404, green: 0.616, blue: 0.902, alpha: 1.0),
        attribute: UIColor(red: 0.631, green: 0.518, blue: 0.369, alpha: 1.0),
        directive: UIColor(red: 0.976, green: 0.475, blue: 0.290, alpha: 1.0),
        plainText: UIColor(red: 0.929, green: 0.929, blue: 0.929, alpha: 1.0)
    )
    
    static let classic = SyntaxColorTheme(
        keyword: UIColor.systemBlue,
        string: UIColor.systemGreen,
        comment: UIColor.systemGray,
        number: UIColor.systemOrange,
        type: UIColor.systemCyan,
        function: UIColor.systemPurple,
        attribute: UIColor.systemYellow,
        directive: UIColor.systemPink,
        plainText: UIColor.label
    )
}
