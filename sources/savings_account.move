module credit_union::savings_account {
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use credit_union::interest_rate;
    use credit_union::credit_union;

    struct SavingsAccount has key {
        owner: address,
        balance: u64,
        interest_rate: u64,
        last_interest_calculation: u64,
    }

   

    public fun withdraw(account: &signer, amount: u64) acquires SavingsAccount {
        let account_address = signer::address_of(account);
        let savings_account = borrow_global_mut<SavingsAccount>(account_address);
        
        assert!(savings_account.balance >= amount, 6);
        
        coin::transfer<AptosCoin>(@credit_union, account_address, amount);
        savings_account.balance -= amount;

        credit_union::update_total_deposits(amount, false);
    }

    public fun calculate_and_add_interest(account: &signer) acquires SavingsAccount {
        let account_address = signer::address_of(account);
        let savings_account = borrow_global_mut<SavingsAccount>(account_address);
        
        let current_time = timestamp::now_seconds();
        let time_elapsed = current_time - savings_account.last_interest_calculation;
        
        let interest = (savings_account.balance * savings_account.interest_rate * time_elapsed) / (100 * 365 * 86400); // Simple interest calculation
        
        savings_account.balance += interest;
        savings_account.last_interest_calculation = current_time;

        credit_union::update_total_deposits(interest, true);
    }

    public fun get_balance(account: address): u64 acquires SavingsAccount {
        let savings_account = borrow_global<SavingsAccount>(account);
        savings_account.balance
    }
}
