
module myPSS


using ControlSystemsBase
using OrderedCollections: OrderedDict
using Modia
@usingModiaPlot


include("utilsPSS.jl")



IniFkt(;kwargs...) = Modia.newCollection(kwargs, :Init)

function ParametersForInit(LL::Vector{String}, x::OrderedDict)
    liste = Expr[]
    for y in LL
        w = x[Symbol(y)]
        if typeof(w) <: AbstractString
            zeile = Meta.parse.("$(y) = \"$(w)\"")
        else
            zeile = Meta.parse.("$(y) = $(w)")
        end
        push!(liste,zeile)
    end
    code = quote
        $(liste...)
        end
    return code
end


function PSS2Binit(para)
    evalVar = NumParametersForInit(para)
    eval(evalVar)
display(evalVar)

    # wash out  A_omega B_power
    aw = tf([Tw1,0],[Tw1,1]) * tf([Tw2,0],[Tw2,1]) * tf([1.0],[T6,1])
    bw = tf([Tw3,0],[Tw3,1]) * tf([Ks2],[T7,1])
    ## ramp tracking
    rt =  (tf([1],[T9,1])^M * tf([T8,1],[1]))^N
    # phase comp
    pc = tf([T1,1],[T2,1]) * tf([T3,1],[T4,1])

    function SetABCD(p, trans)
        S = StateSpace(trans)
        p[:A] = S.A
        p[:B] = S.B
        p[:C] = S.C
        p[:D] = S.D
        p[:x] = zeros(size(S.A)[1])     # alle Eingänge Stabil
        return S
    end

    Saw = SetABCD(para[:washoutA], aw)
    Sbw = SetABCD(para[:washoutB], bw)
    Srt = SetABCD(para[:rampTrack], rt)
    Spc = SetABCD(para[:phaseComp], pc)

    para[:washoutA][:x] = vec(-(Saw.A^-1 * Saw.B*w0)) # inital washoutA
    para[:washoutB][:x] = vec(-(Sbw.A^-1 * Sbw.B*p0)) # inital washoutB

    nothing
end



PSS2Btest = Model(
    initFktL1 = IniFkt(fktcall=PSS2Binit),

    Tw1 = 10.0, Tw2 = 10.0, Tw3 = 10.0,
    T1 = 0.11,  T2 = 0.02,  T3 = 0.11,  T4 = 0.02,
    T6 = 0.0,
    T7 = 10.0,
    M = 5,
    N = 1,
    T8 = 0.5,
    T9 = 0.1,
    Ks1 = 20.0,
    Ks2 = 1.0163377547719183,
    Ks3 = 1.0,

    p0 = 0.5,
    w0 = 0.0,

    Vstmin = -0.05,     Vstmax = 0.1,   #TODO

    out = output,

    washoutA = SS,
    washoutB = SS,
    rampTrack = SS,
    phaseComp = SS,

    equations = :[
        washoutA.u = w0
        washoutB.u = p0+ 0.01*time
        rampTrack.u = washoutA.y[1,1] + Ks3*Pe
        Pe = washoutB.y[1,1]
        Pm = rampTrack.y[1,1]
        Pacc = Pm - Pe
        phaseComp.u = Ks1*Pacc
        out = phaseComp.y[1,1]
    ]
)


instModel = @instantiateModel(PSS2Btest,
    unitless=true,
    log=false,
    logTiming=false,
    logDetails=false,
    logCode=false,
    logFile=false,
    logStateSelection=false,
    evaluateParameters=false,
#         saveCodeOnFile="CODE.txt.jl",
)



PSS2Btest[:initFktL1][:fktcall](instModel.parameters)



@time simulate!(instModel, stopTime=5.0)
@time simulate!(instModel, stopTime=5.0)
@time simulate!(instModel, stopTime=5.0)

plot(instModel, [("out")], figure = 1)
# plot(instModel, [("washoutA.y","washoutB.y"), ("rampTrack.y")], figure = 1)
# plot(instModel, [("rampTrack.u")], figure = 1)


# aus = get_result(instModel, "out")

end

