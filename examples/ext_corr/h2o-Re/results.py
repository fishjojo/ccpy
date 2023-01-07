
def main():

    E_fci = -76.241860

    ndet = [10, 100, 1000, 5000, 10000, 50000, 100000, 500000, 1000000]

    ecCC2 = [-76.2381163421, -76.2381163421, -76.2382230434, -76.2394051049, -76.2399727843,
             -76.2412344106, -76.2414498977, -76.2417401830, -76.2417911800]

    ecCC23 = [-76.2415158332, -76.2415158332, -76.2416242159, -76.2418476722, -76.2417964921,
              -76.2416924708, -76.2416703884, -76.2417545281, -76.2417940558]

    print("  N_det(in)   ec-CC-II     ec-CC-II_3")
    print("--------------------------------------------")
    for i in range(len(ndet)):
            ndet_in = ndet[i]
            error_eccc2 = (ecCC2[i] - E_fci) * 1000
            error_eccc23 = (ecCC23[i] - E_fci) * 1000
            print(f'{ndet_in:9d}    {error_eccc2:9.6f}    {error_eccc23:9.6f}')

if __name__ == "__main__":

    main()