 BEGIN {}
{
    printf "%s-%s" $2 ~ /[AB][0-9]+/ , { print substr($0,1,3)}, "%s\n", strftime("Date: %Y.%m.%d.%H.%M", $1)
    {for(i=3; i<=NF; i++) printf "<br>%s\n", $i}
}

END
