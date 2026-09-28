% ==============================================================================
% EXPERT SYSTEM: CREDIT CARD ELIGIBILITY & TIER EVALUATION SYSTEM
% Language: SWI-Prolog
% ==============================================================================

:- dynamic user_fact/2.

% ------------------------------------------------------------------------------
% 1. KNOWLEDGE BASE: 20 FACTS
% ------------------------------------------------------------------------------
fact(tier_min_income(classic, 100000)).
fact(tier_min_income(gold, 250000)).
fact(tier_min_income(platinum, 400000)).
fact(tier_min_income(signature, 600000)).

fact(credit_limit_multiplier(classic, 2.0)).
fact(credit_limit_multiplier(gold, 3.0)).
fact(credit_limit_multiplier(platinum, 4.0)).
fact(credit_limit_multiplier(signature, 5.0)).

fact(min_age(primary, 21)).
fact(max_age(primary, 65)).
fact(min_age(supplementary, 18)).

fact(min_tenure(salaried, 6)).
fact(min_tenure(self_employed, 24)).

fact(max_dbr_percentage(prime, 55)).
fact(max_dbr_percentage(near_prime, 45)).
fact(max_dbr_percentage(subprime, 0)).

fact(score_band(prime, 750, 900)).
fact(score_band(near_prime, 650, 749)).
fact(score_band(subprime, 300, 649)).

fact(annual_fee(classic, 2500)).
fact(annual_fee(gold, 5000)).
fact(annual_fee(platinum, 10000)).
fact(annual_fee(signature, 20000)).

% ------------------------------------------------------------------------------
% 2. INFERENCE RULES (20 RULES WITH EXPLANATION LOGS)
% ------------------------------------------------------------------------------

% Rule 1: Underage check
rule(r1, rejected('Applicant is below the minimum legal age limit of 21.')) :-
    user_fact(age, A),
    fact(min_age(primary, MinA)),
    A < MinA.

% Rule 2: Overage check
rule(r2, rejected('Applicant exceeds the maximum allowable primary cardholder age of 65.')) :-
    user_fact(age, A),
    fact(max_age(primary, MaxA)),
    A > MaxA.

% Rule 3: Valid Age
rule(r3, eligible_age) :-
    user_fact(age, A),
    fact(min_age(primary, MinA)),
    fact(max_age(primary, MaxA)),
    A >= MinA, A =< MaxA.

% Rule 4: Delinquency Hard Cutoff
rule(r4, rejected('Active default or delinquent payment status recorded in Credit Bureau (CRIB).')) :-
    user_fact(has_overdues, yes).

% Rule 5: Prime bureau score classification
rule(r5, bureau_tier(prime)) :-
    user_fact(has_overdues, no),
    user_fact(crib_score, S),
    fact(score_band(prime, MinS, MaxS)),
    S >= MinS, S =< MaxS.

% Rule 6: Near-prime bureau score classification
rule(r6, bureau_tier(near_prime)) :-
    user_fact(has_overdues, no),
    user_fact(crib_score, S),
    fact(score_band(near_prime, MinS, MaxS)),
    S >= MinS, S =< MaxS.

% Rule 7: Subprime rejection
rule(r7, rejected('Credit Bureau score is below the minimum acceptable credit threshold of 650.')) :-
    user_fact(crib_score, S),
    fact(score_band(subprime, _, MaxS)),
    S =< MaxS.

% Rule 8: Salaried employment tenure failure
rule(r8, rejected('Salaried tenure is less than the mandatory minimum 6 months.')) :-
    user_fact(emp_type, salaried),
    user_fact(tenure, T),
    fact(min_tenure(salaried, MinT)),
    T < MinT.

% Rule 9: Self-employed tenure failure
rule(r9, rejected('Business vintage is less than the mandatory minimum 24 months.')) :-
    user_fact(emp_type, self_employed),
    user_fact(tenure, T),
    fact(min_tenure(self_employed, MinT)),
    T < MinT.

% Rule 10: Verified Employment Tenure
rule(r10, verified_employment) :-
    user_fact(emp_type, salaried),
    user_fact(tenure, T),
    fact(min_tenure(salaried, MinT)),
    T >= MinT.
rule(r10, verified_employment) :-
    user_fact(emp_type, self_employed),
    user_fact(tenure, T),
    fact(min_tenure(self_employed, MinT)),
    T >= MinT.

% Rule 11: DBR Computation
rule(r11, dbr_ratio(DBR)) :-
    user_fact(monthly_income, Income),
    user_fact(existing_debts, Debts),
    Income > 0,
    DBR is (Debts / Income) * 100.

% Rule 12: DBR Failure for Prime
rule(r12, rejected('Total Debt Burden Ratio (DBR) exceeds maximum allowed threshold of 55% for Prime risk tier.')) :-
    rule(r5, bureau_tier(prime)),
    rule(r11, dbr_ratio(DBR)),
    fact(max_dbr_percentage(prime, MaxD)),
    DBR > MaxD.

% Rule 13: DBR Failure for Near-Prime
rule(r13, rejected('Total Debt Burden Ratio (DBR) exceeds maximum allowed threshold of 45% for Near-Prime risk tier.')) :-
    rule(r6, bureau_tier(near_prime)),
    rule(r11, dbr_ratio(DBR)),
    fact(max_dbr_percentage(near_prime, MaxD)),
    DBR > MaxD.

% Rule 14: Minimum Entry Income Threshold Rejection
rule(r14, rejected('Monthly gross income is below the minimum national card threshold of LKR 100,000.')) :-
    user_fact(monthly_income, Income),
    fact(tier_min_income(classic, MinClassic)),
    Income < MinClassic.

% Rule 15: Signature Tier Card Qualification
rule(r15, qualified_card(signature)) :-
    rule(r3, eligible_age),
    rule(r10, verified_employment),
    rule(r5, bureau_tier(prime)),
    user_fact(monthly_income, Income),
    fact(tier_min_income(signature, MinInc)),
    rule(r11, dbr_ratio(DBR)),
    fact(max_dbr_percentage(prime, MaxDBR)),
    DBR =< MaxDBR,
    Income >= MinInc.

% Rule 16: Platinum Tier Card Qualification
rule(r16, qualified_card(platinum)) :-
    rule(r3, eligible_age),
    rule(r10, verified_employment),
    (rule(r5, bureau_tier(prime)) ; rule(r6, bureau_tier(near_prime))),
    user_fact(monthly_income, Income),
    fact(tier_min_income(platinum, MinInc)),
    fact(tier_min_income(signature, MaxInc)),
    Income >= MinInc, Income < MaxInc.

% Rule 17: Gold Tier Card Qualification
rule(r17, qualified_card(gold)) :-
    rule(r3, eligible_age),
    rule(r10, verified_employment),
    (rule(r5, bureau_tier(prime)) ; rule(r6, bureau_tier(near_prime))),
    user_fact(monthly_income, Income),
    fact(tier_min_income(gold, MinInc)),
    fact(tier_min_income(platinum, MaxInc)),
    Income >= MinInc, Income < MaxInc.

% Rule 18: Classic Tier Card Qualification
rule(r18, qualified_card(classic)) :-
    rule(r3, eligible_age),
    rule(r10, verified_employment),
    (rule(r5, bureau_tier(prime)) ; rule(r6, bureau_tier(near_prime))),
    user_fact(monthly_income, Income),
    fact(tier_min_income(classic, MinInc)),
    fact(tier_min_income(gold, MaxInc)),
    Income >= MinInc, Income < MaxInc.

% Rule 19: Approved Credit Limit Calculation
rule(r19, approved_limit(CardTier, Limit)) :-
    user_fact(monthly_income, Income),
    fact(credit_limit_multiplier(CardTier, Multiplier)),
    Limit is Income * Multiplier.

% Rule 20: Comprehensive Decision Formulation
rule(r20, approved(CardTier, Limit, Fee)) :-
    (rule(r15, qualified_card(CardTier)) ;
     rule(r16, qualified_card(CardTier)) ;
     rule(r17, qualified_card(CardTier)) ;
     rule(r18, qualified_card(CardTier))),
    rule(r19, approved_limit(CardTier, Limit)),
    fact(annual_fee(CardTier, Fee)).

% ------------------------------------------------------------------------------
% 3. INFERENCE ENGINE & EXPLANATION FACILITY
% ------------------------------------------------------------------------------

evaluate :-
    % Check for any rejection rules first
    ( rule(RuleID, rejected(Reason)) ->
        format('~n=================================================~n'),
        format('DECISION: APPLICATION REJECTED~n'),
        format('=================================================~n'),
        format('Reason: ~w~n', [Reason]),
        format('Explanation (Rule Triggered): Rule [~w] fired.~n', [RuleID]),
        format('=================================================~n')
    ; rule(r20, approved(Tier, Limit, Fee)) ->
        rule(r11, dbr_ratio(DBR)),
        format('~n=================================================~n'),
        format('DECISION: APPLICATION APPROVED~n'),
        format('=================================================~n'),
        format('Approved Card Product: ~w Card~n', [Tier]),
        format('Approved Credit Limit: LKR ~2f~n', [Limit]),
        format('Annual Membership Fee: LKR ~w~n', [Fee]),
        format('Applicant DBR Ratio  : ~2f%~n', [DBR]),
        format('~nEXPLANATION AUDIT TRAIL:~n'),
        format(' - Baseline eligibility confirmed (Rules r3, r10)~n'),
        format(' - Debt-to-burden verification passed (Rule r11)~n'),
        format(' - Income and Risk-adjusted tier matched (Rule r15-r18)~n'),
        format(' - Final credit limit multiplied via formula (Rules r19, r20)~n'),
        format('=================================================~n')
    ;
        format('~nDECISION: UNABLE TO EVALUATE APPLICATION (Incomplete or edge condition).~n')
    ).

% ------------------------------------------------------------------------------
% 4. USER INTERFACE (CLI INTERACTION)
% ------------------------------------------------------------------------------

start :-
    retractall(user_fact(_, _)),
    format('====================================================~n'),
    format('  RETAIL BANKING CREDIT CARD EVALUATION SYSTEM      ~n'),
    format('====================================================~n'),
    ask_age,
    ask_employment,
    ask_income,
    ask_debts,
    ask_crib,
    evaluate.

ask_age :-
    format('Enter applicant age (years): '),
    read(Age),
    assertz(user_fact(age, Age)).

ask_employment :-
    format('Employment type (salaried. / self_employed.): '),
    read(Type),
    assertz(user_fact(emp_type, Type)),
    format('Continuous tenure in current role/business (in months): '),
    read(Tenure),
    assertz(user_fact(tenure, Tenure)).

ask_income :-
    format('Gross monthly income (LKR): '),
    read(Inc),
    assertz(user_fact(monthly_income, Inc)).

ask_debts :-
    format('Total monthly debt obligations/loans (LKR): '),
    read(Debts),
    assertz(user_fact(existing_debts, Debts)).

ask_crib :-
    format('Any delinquent or overdue records in CRIB? (yes. / no.): '),
    read(Overdue),
    assertz(user_fact(has_overdues, Overdue)),
    format('Credit Bureau Score (300 to 900): '),
    read(Score),
    assertz(user_fact(crib_score, Score)).