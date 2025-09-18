

SS = Model(
    A = parameter | fill(0.0,0,0),
    B = parameter | fill(0.0,0,0),
    C = parameter | fill(0.0,0,0),
    D = parameter | fill(0.0,0,0),
    u = input,
    y = output,
    x = Var(init = zeros(0)),
    equations = :[
        der(x) = A*x + B*u
             y = C*x + D*u
    ]
)


IniFkt(;kwargs...) = Modia.newCollection(kwargs, :Init)



function NumParametersForInit(x::OrderedDict)
    liste = Expr[]
    for (k,v) in x
        if isa(v, Number)
            y = string(k)
            zeile = Meta.parse.("$(y) = $(v)")
            push!(liste,zeile)
        end
    end
    code = quote
        $(liste...)
        end
    return code
end






function SummationCommon(S1,f1,h1,S2,h2)
    A = [S1.A zeros(S1.nx,S2.nx); zeros(S2.nx,S1.nx) S2.A]
    B = [S1.B*f1; S2.B*f1]
    C = [S1.C*h1 S2.C*h2]
    D = [h1*S1.D*f1+h2*S2.D*f1;;]
    StateSpace(A,B,C,D)
end

function Concatenation(S1,f1,h1,S2)
    A = [S1.A zeros(S1.nx,S2.nx); S2.B*S1.C*h1  S2.A]
    B = [S1.B*f1; S2.B*S1.D*f1*h1]
    C = [S2.D*S1.C*h1  S2.C]
    D = [S2.D*S1.D*f1*h1;;]
    StateSpace(A,B,C,D)
end


