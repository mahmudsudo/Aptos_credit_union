module credit_union::loan {
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;
    use credit_union::interest_rate;
    use credit_union::credit_union;

    struct Loan has key {
        borrower: address,
        amount: u64,
        interest_rate: u64,
        due_date: u64,
        is_repaid: bool,
    }

    public fun create_loan(borrower: &signer, amount: u64, duration: u64) acquires Loan {
        let borrower_address = signer::address_of(borrower);
        let interest_rate = interest_rate::get_loan_interest_rate();
        let due_date = timestamp::now_seconds() + duration;

        let loan = Loan {
            borrower: borrower_address,
            amount,
            interest_rate,
            due_date,
            is_repaid: false,
        };

        move_to(borrower, loan);
        coin::transfer<AptosCoin>(@credit_union, borrower_address, amount);
    }

    public fun repay_loan(borrower: &signer, amount: u64) acquires Loan {
        let borrower_address = signer::address_of(borrower);
        let loan = borrow_global_mut<Loan>(borrower_address);
        
        assert!(!loan.is_repaid, 4);
        assert!(amount <= loan.amount, 5);

        coin::transfer<AptosCoin>(borrower, @credit_union, amount);
        loan.amount = loan.amount - amount;

        if (loan.amount == 0) {
            loan.is_repaid = true;
        }

        credit_union::update_total_loans(amount, false);
    }

    public fun get_loan_details(borrower: address): (u64, u64, u64, bool) acquires Loan {
        let loan = borrow_global<Loan>(borrower);
        (loan.amount, loan.interest_rate, loan.due_date, loan.is_repaid)
    }

    public fun calculate_interest(loan: &Loan): u64 {
        let current_time = timestamp::now_seconds();
        let time_elapsed = current_time - loan.due_date;
        (loan.amount * loan.interest_rate * time_elapsed) / (100 * 365 * 86400) // Simple interest calculation
    }

    // Add more functions for loan management
}
