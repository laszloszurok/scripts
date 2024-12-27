#!/usr/bin/env python

# Python script for exchanging currencies.
# Based on: https://github.com/alexanderepstein/Bash-Snippets/blob/master/currency/currency

import argparse
import sys
import requests

from textwrap import dedent


exchange_url: str = "https://open.er-api.com/v6/latest/"

# fmt: off
currencyCodes: list[str] = [
    "AUD", "BAM", "BGN", "BMD", "BND", "BRL", "CAD", "CHF", "CNY", "CZK",
    "DJF", "DKK", "EUR", "GBP", "HKD", "HRK", "HUF", "IDR", "ISK", "ILS",
    "INR", "JPY", "KRW", "MXN", "MYR", "NOK", "NZD", "PAB", "PHP", "PLN",
    "RON", "RUB", "SEK", "SGD", "THB", "TRY", "USD", "ZAR",
]
# fmt: on

currencyCodesFormatted: str = "\n".join(
    "  " + str(currencyCodes[i : i + 5])[1:-1].replace("'", "") + ","
    for i in range(0, len(currencyCodes), 5)
)

description: str = f"""
Description:

Convert between currencies.
With no flags the script will run interactively.

Supported Currencies:

{currencyCodesFormatted}

Examples:
  currency.py -b EUR -t USD -a 12.35
  currency.py
"""


def checkCurrencyCode(currencyCode: str) -> bool:
    return currencyCode in currencyCodes


def getCurrencyCode(prompt: str) -> str:
    currencyCode = input(prompt).upper().strip()
    while not checkCurrencyCode(currencyCode):
        print("Invalid currency code. Please try again.")
        currencyCode = input(prompt).upper().strip()
    return currencyCode


def getAmount() -> float:
    while True:
        try:
            return float(input("What is the amount being exchanged? "))
        except ValueError:
            print("Invalid amount. Please try again.")


def getExchangeRate(baseCurrency: str, targetCurrency: str) -> float:
    if baseCurrency == targetCurrency:
        return 1.0
    return float(
        requests.get(f"{exchange_url}{baseCurrency}").json()["rates"][targetCurrency]
    )


def printResult(
    baseCurrency: str,
    targetCurrency: str,
    exchangeRate: float,
    baseAmount: float,
    resultAmount: float,
) -> None:
    print(
        dedent(
            f"""
            ====================================
            | {baseCurrency} to {targetCurrency}
            | Exchange rate: {exchangeRate}
            | {baseCurrency}: {baseAmount}
            | {targetCurrency}: {resultAmount}
            ====================================
            """
        ).strip("\n")
    )


def convert(
    baseCurrency: str = "", targetCurrency: str = "", baseAmount: float = 0
) -> None:
    if not baseCurrency and not targetCurrency and not baseAmount:
        try:
            baseCurrency = getCurrencyCode("What is the base currency? ")
            targetCurrency = getCurrencyCode("What is the target currency? ")
            baseAmount = getAmount()
        except KeyboardInterrupt:
            sys.exit()
        except EOFError:
            sys.exit()
    exchangeRate: float = getExchangeRate(baseCurrency, targetCurrency)
    resultAmount: float = baseAmount * exchangeRate
    printResult(baseCurrency, targetCurrency, exchangeRate, baseAmount, resultAmount)


parser = argparse.ArgumentParser(
    prog="currency.py",
    description=description,
    usage="%(prog)s [options]",
    formatter_class=argparse.RawTextHelpFormatter,
)
parser.add_argument(
    "-b", "--base-currency", nargs=1, type=str.upper, help="base currency code"
)
parser.add_argument(
    "-t", "--target-currency", nargs=1, type=str.upper, help="target currency code"
)
parser.add_argument("-a", "--amount", nargs=1, type=float, help="base currency amount")
args = parser.parse_args()

if len(sys.argv) == 1:
    convert()
else:
    baseCurrency = args.base_currency[0].strip()
    targetCurrency = args.target_currency[0].strip()
    baseAmount = args.amount[0].strip()
    if checkCurrencyCode(baseCurrency) and checkCurrencyCode(targetCurrency):
        convert(baseCurrency, targetCurrency, baseAmount)
    else:
        print("Invalid currency code. Please try again.")
