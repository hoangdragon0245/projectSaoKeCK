import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/closed_trade.dart';
import '../models/holding_stock.dart';
import '../models/portfolio_summary.dart';
import '../models/transaction.dart';
import '../services/pnl_calculator.dart';
import '../services/storage_service.dart';

class PortfolioState {
  final bool isLoading;
  final List<StockTransaction> transactions;
  final Map<String, double> marketPrices;
  final List<HoldingStock> holdings;
  final List<ClosedTrade> closedTrades;
  final PortfolioSummary summary;
  final String searchQuery;
  final String? filterSymbol;
  final TransactionType? filterType;

  PortfolioState({
    this.isLoading = true,
    this.transactions = const [],
    this.marketPrices = const {},
    this.holdings = const [],
    this.closedTrades = const [],
    required this.summary,
    this.searchQuery = '',
    this.filterSymbol,
    this.filterType,
  });

  PortfolioState copyWith({
    bool? isLoading,
    List<StockTransaction>? transactions,
    Map<String, double>? marketPrices,
    List<HoldingStock>? holdings,
    List<ClosedTrade>? closedTrades,
    PortfolioSummary? summary,
    String? searchQuery,
    String? filterSymbol,
    TransactionType? filterType,
    bool clearFilterSymbol = false,
    bool clearFilterType = false,
  }) {
    return PortfolioState(
      isLoading: isLoading ?? this.isLoading,
      transactions: transactions ?? this.transactions,
      marketPrices: marketPrices ?? this.marketPrices,
      holdings: holdings ?? this.holdings,
      closedTrades: closedTrades ?? this.closedTrades,
      summary: summary ?? this.summary,
      searchQuery: searchQuery ?? this.searchQuery,
      filterSymbol: clearFilterSymbol ? null : (filterSymbol ?? this.filterSymbol),
      filterType: clearFilterType ? null : (filterType ?? this.filterType),
    );
  }

  /// Danh sách sao kê sau khi áp dụng bộ lọc và tìm kiếm
  List<StockTransaction> get filteredTransactions {
    return transactions.where((t) {
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchSymbol = t.symbol.toLowerCase().contains(q);
        final matchNote = t.note.toLowerCase().contains(q);
        if (!matchSymbol && !matchNote) return false;
      }
      if (filterSymbol != null && t.symbol != filterSymbol) {
        return false;
      }
      if (filterType != null && t.type != filterType) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Mới nhất lên đầu
  }

  /// Danh sách các mã cổ phiếu duy nhất có trong lịch sử
  List<String> get availableSymbols {
    final set = transactions.map((e) => e.symbol).toSet().toList();
    set.sort();
    return set;
  }
}

class PortfolioNotifier extends StateNotifier<PortfolioState> {
  PortfolioNotifier()
      : super(PortfolioState(summary: PortfolioSummary.empty())) {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true);
    final txns = await StorageService.loadTransactions();
    final prices = await StorageService.loadMarketPrices();

    final result = PnLCalculator.calculate(
      transactions: txns,
      customMarketPrices: prices,
    );

    state = state.copyWith(
      isLoading: false,
      transactions: txns,
      marketPrices: prices,
      holdings: result.holdings,
      closedTrades: result.closedTrades,
      summary: result.summary,
    );
  }

  void _recalculate() {
    final result = PnLCalculator.calculate(
      transactions: state.transactions,
      customMarketPrices: state.marketPrices,
    );

    state = state.copyWith(
      holdings: result.holdings,
      closedTrades: result.closedTrades,
      summary: result.summary,
    );
  }

  Future<void> addTransaction(StockTransaction txn) async {
    final updatedList = List<StockTransaction>.from(state.transactions)..add(txn);
    await StorageService.saveTransactions(updatedList);
    state = state.copyWith(transactions: updatedList);
    _recalculate();
  }

  Future<void> updateTransaction(StockTransaction txn) async {
    final updatedList = state.transactions.map((t) {
      return t.id == txn.id ? txn : t;
    }).toList();
    await StorageService.saveTransactions(updatedList);
    state = state.copyWith(transactions: updatedList);
    _recalculate();
  }

  Future<void> deleteTransaction(String id) async {
    final updatedList = state.transactions.where((t) => t.id != id).toList();
    await StorageService.saveTransactions(updatedList);
    state = state.copyWith(transactions: updatedList);
    _recalculate();
  }

  Future<void> updateMarketPrice(String symbol, double price) async {
    final updatedPrices = Map<String, double>.from(state.marketPrices);
    updatedPrices[symbol.toUpperCase()] = price;
    await StorageService.saveMarketPrices(updatedPrices);
    state = state.copyWith(marketPrices: updatedPrices);
    _recalculate();
  }

  Future<void> importTransactionsFromCsv(String csvString) async {
    final parsed = StorageService.parseCsv(csvString);
    if (parsed.isEmpty) return;

    final updated = List<StockTransaction>.from(state.transactions)..addAll(parsed);
    await StorageService.saveTransactions(updated);
    state = state.copyWith(transactions: updated);
    _recalculate();
  }

  Future<void> resetDemoData() async {
    final demo = StorageService.getDemoTransactions();
    await StorageService.saveTransactions(demo);
    state = state.copyWith(transactions: demo);
    _recalculate();
  }

  Future<void> clearAll() async {
    await StorageService.clearAll();
    state = state.copyWith(
      transactions: [],
      marketPrices: {},
      holdings: [],
      closedTrades: [],
      summary: PortfolioSummary.empty(),
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilterSymbol(String? symbol) {
    state = state.copyWith(
      filterSymbol: symbol,
      clearFilterSymbol: symbol == null,
    );
  }

  void setFilterType(TransactionType? type) {
    state = state.copyWith(
      filterType: type,
      clearFilterType: type == null,
    );
  }
}

final portfolioProvider =
    StateNotifierProvider<PortfolioNotifier, PortfolioState>((ref) {
  return PortfolioNotifier();
});
