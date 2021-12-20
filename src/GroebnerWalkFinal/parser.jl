cd("/Users/JordiWelp/Results")


function parseideal()
    csv_reader = CSV.File("idealsTest.txt")
    for row in csv_reader
    poly = collect(split("$(row.generator)", ""))
    result = ""
    println("from", poly)
    d = length(poly)
    for i = 1:d
        a = poly[i]
        if i==d
            result = result*a
            println("to", result)
            break
        end
        b = poly[i+1]

        if (a == "+" || a == "-" )
            result = result * a
        else
            if tryparse(Int32, string(a)) != nothing
                if tryparse(Int32, string(b)) != nothing
                    result = result * a
                elseif (b == "+" || b == "-")
                    result = result * a
                else
                    result = result * a * "*"
                end
            else
                if (tryparse(Int32, string(b)) != nothing)
                    result = result * a * "^"
                elseif (b == "+" || b == "-")
                    result = result * a
                else
                    result = result * a * "*"
                end
            end
        end
    end
    df = DataFrame(
    generator= result
    )
    savea(df, "convertedPoly.txt")
end
end
