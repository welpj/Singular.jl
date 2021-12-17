using DataFrames
using CSV
function savew(df::DataFrame, file::String)

  open(file, "w") do io # create a file and write with header as the file does not exist
     foreach(row -> print(io, row), CSV.RowWriter(df))
end
end

function savea(df::DataFrame, file::String)

  open(file, "a") do io # append to file and write without header
             foreach(row -> print(io, row), CSV.RowWriter(df, writeheader=false))
         end
end
