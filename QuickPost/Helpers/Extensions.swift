//
//  Extensions.swift
//  QuickPost
//
//  Created by Tudor Ana on 5/23/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit
import MapKit
import Photos
import UserNotifications

typealias DefaultDictionary = [String : Any]

var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    formatter.timeZone = TimeZone.autoupdatingCurrent
    return formatter
}()

var shortDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy"
    formatter.timeZone = TimeZone.autoupdatingCurrent
    return formatter
}()

var beautyDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "E, MMM d, h:mm a"
    formatter.timeZone = TimeZone.autoupdatingCurrent
    return formatter
}()

func po<T>(_ object: T,
           filename: String = #file,
           line: Int = #line,
           funcname: String = #function,
           isSolo: Bool? = false) {
    
    let className = filename.split{$0 == "/"}.map(String.init).last
    print("[\(Date()) :: \(className ?? "Unknow class") : \(funcname)(\(line))] - \(object)")
}


func playPressKeySound() {
    let PRESS_KEY_DEFAULT_SOUND_ID: SystemSoundID = 1104
    DispatchQueue.main.async() {
        AudioServicesPlaySystemSound(PRESS_KEY_DEFAULT_SOUND_ID)
    }
}

extension UIImage {
    
    func blur(quantity: CGFloat) -> UIImage {
        let context = CIContext(options: nil)
        let inputImage = CIImage(image: self)
        let originalOrientation = self.imageOrientation
        let originalScale = self.scale
        
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(inputImage, forKey: kCIInputImageKey)
        filter?.setValue(quantity, forKey: kCIInputRadiusKey)
        let outputImage = filter?.outputImage
        
        var cgImage:CGImage?
        
        if let asd = outputImage {
            cgImage = context.createCGImage(asd, from: (inputImage?.extent)!)
        }
        
        if let cgImageA = cgImage {
            return UIImage(cgImage: cgImageA, scale: originalScale, orientation: originalOrientation)
        }
        
        return self
    }
    
    var roundedImage: UIImage {
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.width)
        UIGraphicsBeginImageContextWithOptions(self.size, false, 1)
        UIBezierPath(
            roundedRect: rect,
            cornerRadius: self.size.height
            ).addClip()
        self.draw(in: rect)
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
    
    func transform(withNewColor color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(.normal)
        
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        context.clip(to: rect, mask: cgImage!)
        
        color.setFill()
        context.fill(rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}

//MARK: - UIView
extension UIView {
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        } set {
            layer.borderWidth = newValue
        }
    }
    @IBInspectable var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            } else {
                return UIColor.clear
            }
        } set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        } set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var shadowColor: UIColor? {
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            } else {
                return UIColor.clear
            }
        } set {
            layer.shadowColor = newValue?.cgColor
        }
    }
    
    @IBInspectable var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        } set {
            layer.shadowRadius = newValue
        }
    }
    
    @IBInspectable var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        } set {
            layer.shadowOpacity = newValue
        }
    }
    
    @IBInspectable var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        } set {
            layer.shadowOffset = newValue
        }
    }
    
    func addShadow(offset: CGSize, color: UIColor, radius: CGFloat, opacity: Float) {
        let layer = self.layer
        layer.masksToBounds = false
        layer.shadowOffset = offset
        layer.shadowColor = color.cgColor
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        //Optional, to improve performance:
        layer.shadowPath = UIBezierPath.init(roundedRect: layer.bounds, cornerRadius: layer.cornerRadius).cgPath
        
        let backgroundCGColor = self.backgroundColor?.cgColor
        self.backgroundColor = nil
        layer.backgroundColor =  backgroundCGColor
    }
    
    func copyView<T: UIView>() -> T {
        return NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: self)) as! T
    }
    
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
    
    func takeScreenshot() -> UIImage {
        
        // Begin context
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        
        // Draw view in that context
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        
        // And finally, get image
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if (image != nil)
        {
            return image!
        }
        return UIImage()
    }
}

//MARK: - UITextField
extension UITextField{
    @IBInspectable var placeHolderColor: UIColor? {
        get {
            return self.placeHolderColor
        }
        set {
            self.attributedPlaceholder = NSAttributedString(string:self.placeholder != nil ? self.placeholder! : "", attributes:[NSAttributedStringKey.foregroundColor: newValue!])
        }
    }
}


//MARK: - Optional
extension Optional {
    
    func defaultValue(defaultValue: Wrapped) -> Wrapped {
        switch(self) {
        case .none:
            return defaultValue
        case .some(let value):
            return value
        }
    }
}

//MARK: - Data extension
extension Data {
    
    func toDictionary(_ body: (DefaultDictionary?) -> Void) {
        
        do {
            body(try JSONSerialization.jsonObject(with: self, options: []) as? Dictionary)
        } catch _ {
            body(nil)
        }
    }
    
    
    func base64Encoded() -> String {
        let base64String = self.base64EncodedString()
        return base64String
    }
}

extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            // Change `Int` in the next line to `IndexDistance` in < Swift 4.1
            let d: Int = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}

//MARK: - Date
extension Date {
    
    static func timestamp() -> Int {
        return Int((Date().timeIntervalSince1970).rounded())
    }
    
    func stringFromDate(format: String = "yyyy-MM-dd HH:mm") -> String {
        let date = self
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
    
    func getReadableVersion() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat =  "EEEE\nMMMM dd"
        return formatter.string(from: self as Date).uppercased()
    }
    
    func getElapsedDays() -> Int! {
        
        let unitFlags = Set<Calendar.Component>([.day])
        var components = Calendar.current.dateComponents(unitFlags, from: self, to: Date())
        let interval = components.day
        
        if interval! > 0 {
            return interval!
        } else {
            return 0
        }
    }
    
    func getElapsedInterval(shortFormat: Bool) -> String {
        
        
        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "en_US")
        monthFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMM dd", options: 0, locale: NSLocale.current)
        
        let yearFormatter = DateFormatter()
        yearFormatter.locale = Locale(identifier: "en_US")
        yearFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMM dd YYYY", options: 0, locale: NSLocale.current)
        
        let unitFlags = Set<Calendar.Component>([.year, .month, .day, .hour, .minute, .second])
        
        
        
        var components = Calendar.current.dateComponents(unitFlags, from: self, to: Date())
        var interval = components.year
        
        if interval! > 0 {
            return yearFormatter.string(from: self as Date)
        }
        
        interval = components.month
        
        if interval! > 0 {
            return monthFormatter.string(from: self as Date)
        }
        
        interval = components.day
        
        if interval! > 0 {
            if shortFormat {
                return String.localizedStringWithFormat(NSLocalizedString("%d days", comment: "{number of days} days"), interval!)
            } else {
                return String.localizedStringWithFormat(NSLocalizedString("%d %@ ago", comment: "{number of days}d"), interval!, interval! == 1 ? "day" : "days")
            }
        }
        
        interval = components.hour
        
        if interval! > 0 {
            if shortFormat {
                return String.localizedStringWithFormat(NSLocalizedString("%d hrs", comment: "{number h} hrs"), interval!)
            } else {
                return String.localizedStringWithFormat(NSLocalizedString("%d %@ ago", comment: "{number of hours}h"), interval!,
                                                        interval! == 1 ? "hour" : "hours")
            }
        }
        
        interval = components.minute
        
        if interval! > 0 {
            if shortFormat {
                return String.localizedStringWithFormat(NSLocalizedString("%d min", comment: "{number m} min"), interval!)
            } else {
                return String.localizedStringWithFormat(NSLocalizedString("%d %@ ago", comment: "{number of minutes}m"), interval!,
                                                        interval! == 1 ? "minute" : "minutes")
            }
        }
        
        interval = components.second
        
        if interval! > 0 {
            return String.localizedStringWithFormat(NSLocalizedString("Now", comment: "Now"))
        }
        
        if shortFormat {
            return NSLocalizedString("1s", comment: "now")
        } else {
            return NSLocalizedString("1s", comment: "one second ago")
        }
    }
}


extension UNNotificationAttachment {
    
    static func create(identifier: String, image: UIImage, options: [NSObject : AnyObject]?) -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
        let tmpSubFolderURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tmpSubFolderName, isDirectory: true)
        do {
            try fileManager.createDirectory(at: tmpSubFolderURL, withIntermediateDirectories: true, attributes: nil)
            let imageFileIdentifier = identifier + ".png"
            let fileURL = tmpSubFolderURL.appendingPathComponent(imageFileIdentifier)
            
            guard let imageData = UIImagePNGRepresentation(image) else {
                return nil
            }
            try imageData.write(to: fileURL)
            let imageAttachment = try UNNotificationAttachment.init(identifier: imageFileIdentifier, url: fileURL, options: options)
            return imageAttachment
        } catch {
            print("error " + error.localizedDescription)
        }
        return nil
    }
}


//MARK: - String
extension String {
    
    func toDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                po(error.localizedDescription)
            }
        }
        return nil
    }
    
    static func removeUrls(text: String?) -> String? {
        
        if let textT = text {
            var rmvText = textT.replacingOccurrences(of: "@(https?://([-\\w\\.]+[-\\w])+(:\\d+)?(/([\\w/_\\.#-]*(\\?\\S+)?[^\\.\\s])?)?)@", with: "", options: .regularExpression, range: textT.startIndex ..< textT.endIndex)
            rmvText = rmvText.replacingOccurrences(of: "(?i)https?://(?:www\\.)?\\S+(?:/|\\b)", with: "", options: .regularExpression, range: textT.startIndex ..< textT.endIndex)
            
            
            rmvText = rmvText.replacingOccurrences(of: "\\s?#(?:\\S+)\\s?", with: "", options: .regularExpression, range: Range(rmvText.startIndex..<rmvText.endIndex)).trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            
            rmvText = rmvText.replacingOccurrences(of: "\\s?@(?:\\S+)\\s?", with: "", options: .regularExpression, range: Range(rmvText.startIndex..<rmvText.endIndex)).trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            
            rmvText = rmvText.replacingOccurrences(of: "&abreve;", with: "a")
            rmvText = rmvText.replacingOccurrences(of: "&Abreve;", with: "A")
            rmvText = rmvText.replacingOccurrences(of: "&tcedil;", with: "t")
            rmvText = rmvText.replacingOccurrences(of: "&Tcedil;", with: "T")
            rmvText = rmvText.replacingOccurrences(of: "&scedil;", with: "s")
            rmvText = rmvText.replacingOccurrences(of: "&Scedil;", with: "S")
            rmvText = rmvText.replacingOccurrences(of: "&comma;", with: ",")
            rmvText = rmvText.replacingOccurrences(of: "&colon;", with: ":")
            rmvText = rmvText.replacingOccurrences(of: "&period;", with: ".")
            rmvText = rmvText.replacingOccurrences(of: "&vert;", with: "-")
            rmvText = rmvText.replacingOccurrences(of: "&quest;", with: "?")
            rmvText = rmvText.replacingOccurrences(of: "&excl;", with: "!")
            rmvText = rmvText.replacingOccurrences(of: "&lpar;", with: "(")
            rmvText = rmvText.replacingOccurrences(of: "&rpar;", with: ")")
            rmvText = rmvText.replacingOccurrences(of: "&sol;", with: "/")
            rmvText = rmvText.replacingOccurrences(of: "&percnt;", with: "%")
            rmvText = rmvText.replacingOccurrences(of: "&lt;", with: "<")
            rmvText = rmvText.replacingOccurrences(of: "&gt;", with: ">")
            rmvText = rmvText.replacingOccurrences(of: "&le;", with: "<=")
            rmvText = rmvText.replacingOccurrences(of: "&ge;", with: ">=")
            rmvText = rmvText.replacingOccurrences(of: "&hellip;", with: "...")
            rmvText = rmvText.replacingOccurrences(of: "&amp;", with: "&")
            rmvText = rmvText.replacingOccurrences(of: "&ldquo;", with: "\"")
            rmvText = rmvText.replacingOccurrences(of: "&rdquo;", with: "\"")
            rmvText = rmvText.replacingOccurrences(of: "&rsquo;", with: "'")
            rmvText = rmvText.replacingOccurrences(of: "\"", with: "")
            rmvText = rmvText.replacingOccurrences(of: "“", with: "")
            rmvText = rmvText.replacingOccurrences(of: "”", with: "")
            
            rmvText = rmvText.replacingOccurrences(of: "&mdash;", with: "—")
            rmvText = rmvText.replacingOccurrences(of: "&ndash;", with: "—")
            rmvText = rmvText.replacingOccurrences(of: "&middot;", with: "·")
            rmvText = rmvText.replacingOccurrences(of: "&micro;", with: "µ")
            rmvText = rmvText.replacingOccurrences(of: "&permil;", with: "‰")
            rmvText = rmvText.replacingOccurrences(of: "&deg;", with: "°")
            rmvText = rmvText.replacingOccurrences(of: "&trade;", with: "™")
            rmvText = rmvText.replacingOccurrences(of: "&reg;", with: "®")
            rmvText = rmvText.replacingOccurrences(of: "&copy;", with: "©")
            rmvText = rmvText.replacingOccurrences(of: "&dagger;", with: "†")
            rmvText = rmvText.replacingOccurrences(of: "&bull;", with: "•")
            rmvText = rmvText.replacingOccurrences(of: "&raquo;", with: "»")
            rmvText = rmvText.replacingOccurrences(of: "&laquo;", with: "«")
            rmvText = rmvText.replacingOccurrences(of: "&pound;", with: "£")
            rmvText = rmvText.replacingOccurrences(of: "&euro;", with: "€")
            
            //Romanian
            rmvText = rmvText.replacingOccurrences(of: "&#258;", with: "Ă")
            rmvText = rmvText.replacingOccurrences(of: "&Acirc;", with: "Â")
            rmvText = rmvText.replacingOccurrences(of: "&Icirc;", with: "Î")
            rmvText = rmvText.replacingOccurrences(of: "&#350;", with: "Ş")
            rmvText = rmvText.replacingOccurrences(of: "&#354;", with: "Ţ")
            rmvText = rmvText.replacingOccurrences(of: "&#259;", with: "ă")
            rmvText = rmvText.replacingOccurrences(of: "&acirc;", with: "â")
            rmvText = rmvText.replacingOccurrences(of: "&icirc;", with: "î")
            rmvText = rmvText.replacingOccurrences(of: "&#351;", with: "ş")
            rmvText = rmvText.replacingOccurrences(of: "&#355;", with: "ţ")
            
            //German
            rmvText = rmvText.replacingOccurrences(of: "&Auml;", with: "Ä")
            rmvText = rmvText.replacingOccurrences(of: "&Ouml;", with: "Ö")
            rmvText = rmvText.replacingOccurrences(of: "&Uuml;", with: "Ü")
            rmvText = rmvText.replacingOccurrences(of: "&auml;", with: "ä")
            rmvText = rmvText.replacingOccurrences(of: "&ouml;", with: "ö")
            rmvText = rmvText.replacingOccurrences(of: "&uuml;", with: "ü")
            rmvText = rmvText.replacingOccurrences(of: "&szlig;", with: "ß")
            
            //French
            rmvText = rmvText.replacingOccurrences(of: "&Agrave;", with: "À")
            rmvText = rmvText.replacingOccurrences(of: "&Ccedil;", with: "Ç")
            rmvText = rmvText.replacingOccurrences(of: "&Egrave;", with: "È")
            rmvText = rmvText.replacingOccurrences(of: "&Eacute;", with: "É")
            rmvText = rmvText.replacingOccurrences(of: "&Ecirc;", with: "Ê")
            rmvText = rmvText.replacingOccurrences(of: "&Euml;", with: "Ë")
            rmvText = rmvText.replacingOccurrences(of: "&Iuml;", with: "Ï")
            rmvText = rmvText.replacingOccurrences(of: "&Ocirc;", with: "Ô")
            rmvText = rmvText.replacingOccurrences(of: "&OElig;", with: "Œ")
            rmvText = rmvText.replacingOccurrences(of: "&Ugrave;", with: "Ù")
            rmvText = rmvText.replacingOccurrences(of: "&Ucirc;", with: "Û")
            rmvText = rmvText.replacingOccurrences(of: "&Uuml;", with: "Ü")
            rmvText = rmvText.replacingOccurrences(of: "&#376;", with: "Ÿ")
            
            rmvText = rmvText.replacingOccurrences(of: "&agrave;", with: "à")
            rmvText = rmvText.replacingOccurrences(of: "&ccedil;", with: "ç")
            rmvText = rmvText.replacingOccurrences(of: "&egrave;", with: "è")
            rmvText = rmvText.replacingOccurrences(of: "&eacute;", with: "é")
            rmvText = rmvText.replacingOccurrences(of: "&ecirc;", with: "ê")
            rmvText = rmvText.replacingOccurrences(of: "&euml;", with: "ë")
            rmvText = rmvText.replacingOccurrences(of: "&iuml;", with: "ï")
            rmvText = rmvText.replacingOccurrences(of: "&ocirc;", with: "ô")
            rmvText = rmvText.replacingOccurrences(of: "&oElig;", with: "œ")
            rmvText = rmvText.replacingOccurrences(of: "&ugrave;", with: "ù")
            rmvText = rmvText.replacingOccurrences(of: "&ucirc;", with: "û")
            rmvText = rmvText.replacingOccurrences(of: "&uuml;", with: "ü")
            rmvText = rmvText.replacingOccurrences(of: "&yuml;", with: "ÿ")
            
            
            
            
            let components = rmvText.components(separatedBy: "Twitter:")
            if components.count > 1 {
                rmvText = components[1]
            }
            
            return rmvText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }
    
    func dictionary() -> DefaultDictionary? {
        if let data = self.data(using: String.Encoding.utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Dictionary
            } catch {
                return nil
            }
        }
        return nil
    }
    
    func toDictionary(_ body: (DefaultDictionary?) -> Void) {
        
        if let data = self.data(using: String.Encoding.utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? DefaultDictionary
                body(json)
            } catch {
                body(nil)
            }
        }
    }
    
    func removeSpecialCharsFromString() -> String {
        let okayChars : Set<Character> =
            Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890+-*=(),.:!_")
        return String(self.filter {okayChars.contains($0) })
    }
}

//MARK: - Array
extension Array where Element: Equatable {
    
    mutating func remove(object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}


//MARK: - UISearchBarViewController
extension UISearchController {
    
    public func preferredStatusBarStyle() -> UIStatusBarStyle{
        return UIStatusBarStyle.lightContent
    }
}

extension UISearchBar {
    
    private func getViewElement<T>(type: T.Type) -> T? {
        
        let svs = subviews.flatMap { $0.subviews }
        guard let element = (svs.filter { $0 is T }).first as? T else { return nil }
        return element
    }
    
    func getSearchBarTextField() -> UITextField? {
        
        return getViewElement(type: UITextField.self)
    }
    
    func setTextColor(color: UIColor) {
        
        if let textField = getSearchBarTextField() {
            textField.textColor = color
        }
    }
    
    func setTextFieldColor(color: UIColor) {
        
        if let textField = getViewElement(type: UITextField.self) {
            switch searchBarStyle {
            case .minimal:
                textField.layer.backgroundColor = color.cgColor
                textField.layer.cornerRadius = 6
                
            case .prominent, .default:
                textField.backgroundColor = color
            }
        }
    }
    
    func setTextFieldClearButtonColor(color: UIColor) {
        
        if let textField = getSearchBarTextField() {
            
            let button = textField.value(forKey: "clearButton") as! UIButton
            if let image = button.imageView?.image {
                button.setImage(image.transform(withNewColor: color), for: .normal)
            }
        }
    }
    
    func setSearchImageColor(color: UIColor) {
        
        if let imageView = getSearchBarTextField()?.leftView as? UIImageView {
            imageView.image = imageView.image?.transform(withNewColor: color)
        }
    }
}


let imageCache = NSCache<AnyObject, UIImage>()
extension UIImageView {
    
    public func imageFrom(url: String?) {
        
        
        guard let urlT = url else { return }
        
        if let cachedImage = imageCache.object(forKey: urlT as AnyObject) {
            self.backgroundColor = UIColor.clear
            self.image = cachedImage
        } else {
            self.image = nil
            guard let goodUrl = URL(string: urlT) else { return }
            URLSession.shared.dataTask(with: goodUrl, completionHandler: { (data, response, error) -> Void in
                
                guard error == nil,
                    let image = UIImage(data: data!) else { return }
                DispatchQueue.main.safeAsync { [weak self] in
                    guard let _ = self else { return }
                    imageCache.setObject(image, forKey: url as AnyObject)
                    self!.image = image
                    imageCache.setObject(image, forKey: url as AnyObject)
                }
            }).resume()
        }
    }
}




extension UINavigationBar {
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 51)
    }
}


//MARK: - Bundle
extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    var displayName: String? {
        return "ec-igquickpost"
    }
}

extension PHAsset {
    
    func getURL(completionHandler : @escaping ((_ responseURL : URL?) -> Void)){
        if self.mediaType == .image {
            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                return true
            }
            self.requestContentEditingInput(with: options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [AnyHashable : Any]) -> Void in
                completionHandler(contentEditingInput!.fullSizeImageURL as URL?)
            })
        } else if self.mediaType == .video {
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.version = .original
            PHImageManager.default().requestAVAsset(forVideo: self, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
                if let urlAsset = asset as? AVURLAsset {
                    let localVideoUrl: URL = urlAsset.url as URL
                    completionHandler(localVideoUrl)
                } else {
                    completionHandler(nil)
                }
            })
        }
    }
}

extension URL {
    
    public var queryParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true), let queryItems = components.queryItems else {
            return nil
        }
        
        var parameters = [String: String]()
        for item in queryItems {
            parameters[item.name] = item.value
        }
        
        return parameters
    }
}


extension UIColor {
    
    func lighter(by percentage: CGFloat = 10.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }
    
    func darker(by percentage: CGFloat = 10.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }
    
    func adjust(by percentage: CGFloat = 10.0) -> UIColor? {
        var r:CGFloat=0, g:CGFloat=0, b:CGFloat=0, a:CGFloat=0;
        if(self.getRed(&r, green: &g, blue: &b, alpha: &a)){
            return UIColor(red: min(r + percentage/100, 1.0),
                           green: min(g + percentage/100, 1.0),
                           blue: min(b + percentage/100, 1.0),
                           alpha: a)
        }else{
            return nil
        }
    }
    
    var inverted: UIColor {
        var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0
        UIColor.red.getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: (1 - r), green: (1 - g), blue: (1 - b), alpha: a)
    }
    
    class func hexString(hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    class var tintColor: UIColor {
        return UIColor(red: 205/255, green: 67/255, blue: 129/255, alpha: 1.0)
    }
    
    class var backgroundColor: UIColor {
        return UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1.0)
    }
}


extension UIViewController {
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 250 / 2, y: self.view.frame.size.height-100, width: 250, height: 40))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 15.0)
        toastLabel.text = message
        toastLabel.alpha = 0.0
        toastLabel.layer.cornerRadius = 20;
        toastLabel.clipsToBounds  =  true
        self.navigationController?.view.addSubview(toastLabel)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            toastLabel.alpha = 1.0
        }, completion: {(isCompleted) in
            if isCompleted {
                UIView.animate(withDuration: 1, delay: 2, options: .curveEaseOut, animations: {
                    toastLabel.alpha = 0.0
                }, completion: {(isCompleted) in
                    toastLabel.removeFromSuperview()
                })
            }
        })
        
        //        UIView.animate(withDuration: 1, delay: 2, options: .curveEaseOut, animations: {
        //            toastLabel.alpha = 0.0
        //        }, completion: {(isCompleted) in
        //            toastLabel.removeFromSuperview()
        //        })
    }
}



extension CLPlacemark {
    
    var compactAddress: String? {
        if name != nil {
            var result = ""
            
            if let streetNum = subThoroughfare {
                result += streetNum
            }
            
            if let street = thoroughfare {
                result += " \(street)"
            }
            
            if let city = locality {
                result += " \(city)"
            }
            
            if let country = country {
                result += " \(country)"
            }
            
            if result.hasPrefix(" ") {
                result.remove(at: result.startIndex)
            }
            
            return result
        }
        
        return nil
    }
    
}




//MARK: - DispatchQueue extension
extension DispatchQueue {
    
    func safeAsync(_ block: @escaping ()->()) {
        if self === DispatchQueue.main && Thread.isMainThread {
            block()
        } else {
            async { block() }
        }
    }
    
    static func background(delay: Double = 0.0, background: (()->Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }
}


extension NSMutableAttributedString {
    
    func set(color: UIColor, for text: String) {
        let range: NSRange = self.mutableString.range(of: text, options: .caseInsensitive)
        self.addAttribute(NSAttributedStringKey.foregroundColor, value: color, range: range)
    }
    
}



extension String {
    
    func indexDistance(of character: Character) -> Int? {
        guard let index = self.index(of: character) else { return nil }
        return distance(from: startIndex, to: index)
    }
    
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    subscript (bounds: CountableRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ..< end]
    }
    subscript (bounds: CountableClosedRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ... end]
    }
    subscript (bounds: CountablePartialRangeFrom<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(endIndex, offsetBy: -1)
        return self[start ... end]
    }
    subscript (bounds: PartialRangeThrough<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ... end]
    }
    subscript (bounds: PartialRangeUpTo<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ..< end]
    }
}
extension Substring {
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    subscript (bounds: CountableRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ..< end]
    }
    subscript (bounds: CountableClosedRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ... end]
    }
    subscript (bounds: CountablePartialRangeFrom<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(endIndex, offsetBy: -1)
        return self[start ... end]
    }
    subscript (bounds: PartialRangeThrough<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ... end]
    }
    subscript (bounds: PartialRangeUpTo<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ..< end]
    }
}

extension UILabel {
    
    func lines() -> Int {
        var lineCount = 0;
        let textSize = CGSize(width: self.frame.size.width, height: CGFloat(Float.infinity));
        let rHeight = lroundf(Float(self.sizeThatFits(textSize).height))
        let charSize = lroundf(Float(self.font.lineHeight));
        lineCount = rHeight/charSize
        return lineCount
    }
    
    func colorHashtag(with color: UIColor) {
        let text = self.text

        let titleDict: NSDictionary = [NSAttributedStringKey.font: self.font]
        let attributedString = NSMutableAttributedString(string: text!, attributes: titleDict as! [NSAttributedStringKey : AnyObject])
        
        let hashtagregex = try? NSRegularExpression(pattern: "#(\\w+)", options: [])
        let hashtagmatches = hashtagregex!.matches(in: text!, options: [], range: NSMakeRange(0, text!.count))
        
        for match in hashtagmatches {
            let matchRange = match.range(at: 0)
            let titleDict: NSDictionary = [NSAttributedStringKey.foregroundColor: color]
            attributedString.addAttributes(titleDict as! [NSAttributedStringKey : AnyObject], range: matchRange)
        }
        
        
        self.attributedText = attributedString
    }
    
}


