//
//  ViewController.swift
//  LiteBlue
//
//  Created by WhitetailAni on 12/18/25.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    var webView: WKWebView!
    let group = DispatchGroup()
    
    var bar: UIToolbar!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    override func loadView() {
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: .init(x: 0, y: 0, width: 1920, height: 1080), configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUpWebView { //[weak self] in
            let url = URL(string: "https://liteblue.usps.gov/wps/myportal")
            let request = URLRequest(url: url!)
            self.webView.load(request)
            
            self.bar = UIToolbar()
            let appearance = UIToolbarAppearance()
            appearance.backgroundColor = .black
            self.bar.standardAppearance = appearance
            self.bar.scrollEdgeAppearance = appearance
            self.bar.translatesAutoresizingMaskIntoConstraints = false
            
            //let tint = self.view.tintColor
            
            let back = UIBarButtonItem(
                image: UIImage(systemName: "chevron.left"),
                style: .plain,
                target: self.webView,
                action: #selector(WKWebView.goBack))
            let forward = UIBarButtonItem(
                image: UIImage(systemName: "chevron.right"),
                style: .plain,
                target: self.webView,
                action: #selector(WKWebView.goForward))
            let reload = UIBarButtonItem(
                image: UIImage(systemName: "arrow.counterclockwise"),
                style: .plain,
                target: self.webView,
                action: #selector(WKWebView.reload))
            
            back.tintColor = .systemTeal
            forward.tintColor = .systemTeal
            reload.tintColor = .systemTeal
            
            back.imageInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
            forward.imageInsets = UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 0)
            reload.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15)

            self.bar.items = [back, forward, UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), reload
            ]
            
            self.view.addSubview(self.bar)
            
            NSLayoutConstraint.activate([
                self.bar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                self.bar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                self.bar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                
                self.webView.bottomAnchor.constraint(equalTo: self.bar.topAnchor)
            ])
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            self.setData(cookies, key: "cookies")
        }
    }
    
    private func setUpWebView(_ completion: @escaping () -> Void) {
        func setup(config: WKWebViewConfiguration) {
            self.webView = WKWebView(frame: CGRect.zero, configuration: config)
            self.webView.uiDelegate = self
            self.webView.navigationDelegate = self
            self.webView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(self.webView)
            
            NSLayoutConstraint.activate([
                self.webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                self.webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                self.webView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            ])
        }
        
        self.configurationForWebView { config in
            setup(config: config)
            completion()
        }
    }
    
    
    //store cookies
    private func configurationForWebView(_ completion: @escaping (WKWebViewConfiguration) -> Void) {
        let configuration = WKWebViewConfiguration()
        
        let processPool: WKProcessPool

        if let pool: WKProcessPool = self.getData(key: "pool")  {
            processPool = pool
        } else {
            processPool = WKProcessPool()
            self.setData(processPool, key: "pool")
        }

        configuration.processPool = processPool
        
        if let cookies: [HTTPCookie] = self.getData(key: "cookies") {
            for cookie in cookies {
                group.enter()
                configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
                    self.group.leave()
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            completion(configuration)
        }
    }
    
    func setData(_ value: Any, key: String) {
        let defaults = UserDefaults.standard
        do {
            let archivedPool = try NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false)
            defaults.set(archivedPool, forKey: key)
        } catch {
            print("uh oh!")
        }
    }

    func getData<T>(key: String) -> T? {
        let ud = UserDefaults.standard
        if let val = ud.value(forKey: key) as? Data, let obj = NSKeyedUnarchiver.unarchiveObject(with: val) as? T {
            return obj
        }
        
        return nil
    }
    
    //open new link
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil || !navigationAction.targetFrame!.isMainFrame {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
