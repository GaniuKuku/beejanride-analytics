{% macro calculate_net_revenue(payment_amount, payment_fee) %}

    coalesce({{ payment_amount }}, 0)
    - coalesce({{ payment_fee }}, 0)

{% endmacro %}
