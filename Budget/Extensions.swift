//
//  Extensions.swift
//  Budget
//
//  Created by Cory Iley on 3/11/22.
//

import Foundation

extension Date {
    
    /// Return formatted string with given format
    func stringWithFormat(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    /// Get start of specified calendar component
    func getStart(of component: Calendar.Component, calendar: Calendar = Calendar.current) -> Date? {
        return calendar.dateInterval(of: component, for: self)?.start
    }
    
    /// Get end of specified calendar component
    func getEnd(of component: Calendar.Component, calendar: Calendar = Calendar.current) -> Date? {
        return calendar.dateInterval(of: component, for: self)?.end
    }
}

extension Decimal {
    mutating func round(_ scale: Int, _ roundingMode: NSDecimalNumber.RoundingMode) {
        var localCopy = self
        NSDecimalRound(&self, &localCopy, scale, roundingMode)
    }

    func rounded(_ scale: Int, _ roundingMode: NSDecimalNumber.RoundingMode) -> Decimal {
        var result = Decimal()
        var localCopy = self
        NSDecimalRound(&result, &localCopy, scale, roundingMode)
        return result
    }
    
    var isWholeNumber: Bool { isZero ? true : !isNormal ? false : self == rounded(0, .bankers) }
    
    var currencyFormatted: String {
            Formatter.currency.minimumFractionDigits = isWholeNumber ? 0 : 2
            return Formatter.currency.string(for: self) ?? ""
        }
    
    var currencyNoSymbolFormatted: String {
        Formatter.currencyNoSymbol.minimumFractionDigits = isWholeNumber ? 0 : 2
        return Formatter.currencyNoSymbol.string(for: self) ?? ""
    }
}

extension Formatter {
    static let currency: NumberFormatter = {
        let numberFormater = NumberFormatter()
        numberFormater.numberStyle = .currency
        return numberFormater
    }()
    
    static let currencyNoSymbol: NumberFormatter = {
        let numberFormater = NumberFormatter()
        numberFormater.numberStyle = .currency
        numberFormater.currencySymbol = ""
        return numberFormater
    }()
}


extension String {
    /// Remove localized currency symbols
    public func removeFormatAmount() -> String {
        self
            .replacingOccurrences(of: Locale.current.currencySymbol ?? "", with: "")
            .replacingOccurrences(of: Locale.current.groupingSeparator ?? "", with: "")
    }
    
    
}
