//
//  ZZGuideController.swift
//
//  Created by Apple on 2017/5/8.
//

import UIKit

fileprivate extension String {
    
    func ks_size(of font: UIFont, maxWidth: CGFloat) -> CGSize {
        let s = self as NSString
        let size = s.boundingRect(with: CGSize(width: maxWidth, height: .infinity), options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine, .usesFontLeading], attributes: [NSAttributedString.Key.font: font], context: nil).size
        return size;
    }
    
}

public class ZZGuideController: UIViewController {
    
    enum Region {
        case upperLeft
        case upperRight
        case lowerLeft
        case lowerRight
    }
    
    public typealias CompletionBlock = (() -> Void)
    public typealias IndexChangeBlock = ((_ index: Int, _ item: ZZGuideItem) -> Void)
    
    private var items = [ZZGuideItem]()
    public var currentIndex: Int = -1 {
        didSet {
            self.indexWillChangeBlock?(currentIndex, self.currentItem)
            configViews()
            self.indexDidChangeBlock?(currentIndex, self.currentItem)
        }
    }
    private var currentItem: ZZGuideItem {
        get {
            return items[currentIndex]
        }
    }
    private let arrowImageView = UIImageView()
    private let textLabel = UILabel()
    
    private let maskLayer = CAShapeLayer()
    private var completion: CompletionBlock?
    private var indexWillChangeBlock: IndexChangeBlock?
    private var indexDidChangeBlock: IndexChangeBlock?
    private var guideKey: String?
    
    public var maskCornerRadius: CGFloat = 8
    public var backgroundAlpha: CGFloat = 0.7
    public var spacing: CGFloat = 20
    public var padding: CGFloat = 50
    public var maskInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    public var font = UIFont.systemFont(ofSize: 14)
    public var textColor = UIColor.white
    public var arrowColor = UIColor.white
    
    public var arrowImage: UIImage?
    public var animationDuration = 0.2
    public var animatedMask = true
    public var animatedText = true
    public var animatedArrow = true
    
    public var statusBarHidden = false
    
    private var maskCenter: CGPoint {
        get {
            return CGPoint(x: hollowFrame.midX, y: hollowFrame.midY)
        }
    }
    
    private var region: Region {
        get {
            let center = maskCenter
            let bounds = view.bounds
            if center.x <= bounds.midX && center.y <= bounds.midY {
                return .upperLeft
            } else if center.x > bounds.midX && center.y <= bounds.midY {
                return .upperRight
            } else if center.x <= bounds.midX && center.y > bounds.midY {
                return .lowerLeft
            } else {
                return .lowerRight
            }
        }
    }
    
    private var hollowFrame: CGRect {
        get {
            var rect: CGRect = .zero
            if let sourceView = currentItem.sourceView {
                let systemVersion = (UIDevice.current.systemVersion as NSString).floatValue
                if systemVersion >= 8.0 && systemVersion < 9.0 {
                    if let superView = sourceView.superview {
                        rect = view.convert(sourceView.frame, from: superView)
                    } else {
                        assertionFailure("sourceView must have a superView!")
                    }
                } else {
                    rect = view.convert(sourceView.frame, from: sourceView.superview)
                }
            } else {
                rect = currentItem.rect
            }
            rect.origin.x += maskInsets.left
            rect.origin.y += maskInsets.top
            rect.size.width -= maskInsets.right + maskInsets.left
            rect.size.height -= maskInsets.bottom + maskInsets.top
            return rect
        }
    }
    
    public convenience init(item: ZZGuideItem, key: String?) {
        self.init(items: [item], key: key)
    }
    
    public init(items: [ZZGuideItem], key: String?) {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        modalTransitionStyle = .crossDissolve
        self.items.append(contentsOf: items)
        self.guideKey = key
    }
    
    public func show(from vc: UIViewController, completion:CompletionBlock?) {
        self.completion = completion
        if let key = guideKey {
            if ZZGuideDataManager.shouldShowGuide(with: key) {
                vc.present(self, animated: true, completion: nil)
            }
        } else {
            vc.present(self, animated: true, completion: nil)
        }
    }
    
    public func setIndexWillChangeBlock(_ block: IndexChangeBlock?) {
        indexWillChangeBlock = block
    }
    
    public func setIndexDidChangeBlock(_ block: IndexChangeBlock?) {
        indexDidChangeBlock = block;
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        currentIndex = 0
    }
    
    public override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (ctx) in
            self.configMask()
            self.configViewFrames()
        }, completion: nil)
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func configViews() {
        view.backgroundColor = UIColor(white: 0, alpha: backgroundAlpha)
        
        if let image = currentItem.arrowImage {
            arrowImageView.image = image
        } else if let image = arrowImage {
            arrowImageView.image = image
        } else {
            arrowImageView.image = BundleImage("arrow")
        }
        arrowImageView.image = arrowImageView.image?.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        arrowImageView.tintColor = arrowColor
        view.addSubview(arrowImageView)
        
        textLabel.textColor = textColor
        textLabel.font = font
        textLabel.textAlignment = .left
        textLabel.text = currentItem.text
        textLabel.numberOfLines = 0
        view.addSubview(textLabel)
        
        configMask()
        configViewFrames()
    }
    
    private func configMask() {
        let fromPath = maskLayer.path
        
        maskLayer.fillColor = UIColor.black.cgColor
        var radius = maskCornerRadius
        let frame = hollowFrame
        radius = min(radius, min(frame.width / 2.0, frame.height / 2.0))
        let highlightedPath = UIBezierPath(roundedRect: hollowFrame, cornerRadius: radius)
        let toPath = UIBezierPath(rect: view.bounds)
        toPath.append(highlightedPath)
        maskLayer.path = toPath.cgPath
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        view.layer.mask = maskLayer
        
        if animatedMask {
            let animation = CABasicAnimation(keyPath: "path")
            animation.duration = animationDuration
            animation.fromValue = fromPath
            animation.toValue = toPath
            maskLayer.add(animation, forKey: nil)
        }
    }
    
    private func configViewFrames() {
        maskLayer.frame = view.bounds
        
        var textRect: CGRect!
        var arrowRect: CGRect!
        var transform: CGAffineTransform = .identity
        let imageSize = arrowImageView.image!.size
        let maxWidth = view.frame.size.width - padding * 2
        let size = currentItem.text.ks_size(of: font, maxWidth: maxWidth)
        let maxX = padding + maxWidth - size.width
        switch region {
            
        case .upperLeft:
            transform = CGAffineTransform(scaleX: -1, y: 1)
            arrowRect = CGRect(x: hollowFrame.midX - imageSize.width / 2,
                               y: hollowFrame.maxY + spacing,
                               width: imageSize.width,
                               height: imageSize.height)
            let x: CGFloat = max(padding, min(maxX, arrowRect.maxX - size.width / 2))
            textRect = CGRect(x: x,
                              y: arrowRect.maxY + spacing,
                              width: size.width,
                              height: size.height)
            
        case .upperRight:
            arrowRect = CGRect(x: hollowFrame.midX - imageSize.width / 2,
                               y: hollowFrame.maxY + spacing,
                               width: imageSize.width,
                               height: imageSize.height)
            let x: CGFloat = max(padding, min(maxX, arrowRect.minX - size.width / 2))
            textRect = CGRect(x: x,
                              y: arrowRect.maxY + spacing,
                              width: size.width,
                              height: size.height)
            
        case .lowerLeft:
            transform = CGAffineTransform(scaleX: 1, y: 1)
            arrowRect = CGRect(x: spacing,
                               y: hollowFrame.minY - spacing - imageSize.height,
                               width: imageSize.width,
                               height: imageSize.height)
            let x: CGFloat = max(padding, min(maxX, arrowRect.maxX - size.width / 2))
            textRect = CGRect(x: x,
                              y: arrowRect.minY - spacing - size.height,
                              width: size.width,
                              height: size.height)
            
        case .lowerRight:
            transform = CGAffineTransform(scaleX: 1, y: 1)
            arrowRect = CGRect(x: hollowFrame.maxX - imageSize.width,
                               y: hollowFrame.minY - spacing - imageSize.height,
                               width: imageSize.width,
                               height: imageSize.height)
            let x: CGFloat = max(padding, min(maxX, arrowRect.minX - size.width / 2))
            textRect = CGRect(x: x,
                              y: arrowRect.minY - spacing - size.height,
                              width: size.width,
                              height: size.height)
        }
        if animatedArrow && animatedText {
            UIView.animate(withDuration: animationDuration, animations: {
                self.arrowImageView.transform = transform
                self.arrowImageView.frame = arrowRect
                self.textLabel.frame = textRect
            }, completion: nil)
            return
        }
        if animatedArrow {
            UIView.animate(withDuration: animationDuration, animations: {
                self.arrowImageView.transform = transform
                self.arrowImageView.frame = arrowRect
            }, completion: nil)
            self.textLabel.frame = textRect
            return
        }
        if animatedText {
            UIView.animate(withDuration: animationDuration, animations: {
                self.textLabel.frame = textRect
            }, completion: nil)
            self.arrowImageView.transform = transform
            self.arrowImageView.frame = arrowRect
            return
        }
        arrowImageView.transform = transform
        arrowImageView.frame = arrowRect
        textLabel.frame = textRect
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if currentIndex < items.count - 1 {
            currentIndex += 1
        } else {
            dismiss(animated: true, completion: completion)
        }
    }
    
    private func BundleImage(_ name: String) -> UIImage? {
        let bundle = Bundle(for: ZZGuideController.self)
        guard let url = bundle.url(forResource: "Images", withExtension: "bundle")?.appendingPathComponent(name).appendingPathExtension("png") else {
            return nil
        }
        guard let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        return image
    }
    
}
