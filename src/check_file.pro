pro check_file, file

; author: Avijeet Prasad
; created on: 2022/08/15
; purpose: Check if a file exists, if not then prompt user
; input: file (filepath)   
; updates:

result = file_test(file) 
print, 'Check if ' + file + 'exists ? ', result ? 'Yes!' : 'No!, Check input!!!'
end 