function _match_macro(var, cases)
    (length(cases) == 0) && return :nothing

    pair = cases[1]
    @assert(pair.head == :call && pair.args[1] == :(=>))
    key = esc(pair.args[2])
    val = esc(pair.args[3])
    tail_match = _match_macro(var, Base.tail(cases))
    return Expr(:if, :($var == $key), val, tail_match)
end

macro _match(var, cases...)
    var = esc(var)
    return _match_macro(var, cases)
end

macro _check_argument_in_array(var, vals...)
    error_msg = "invalid value for $var, must be " * join(string.(vals[1:end-1]), ", ") * ", or $(vals[end])"
    vals_tuple = Expr(:tuple, vals...)
    var = esc(var)
    return :(($var in $vals_tuple) || throw(ArgumentError($error_msg)))
end
